classdef FourPort < handle
	% abstract representation of a four port transmission device
	% It can not be changed once initialized; however, symbolic expressions
	% can be used to tune the model after construction
	
	% Static methods are used to construct common integrated devices
	% i.e. waveguide, coupler, mrrFilter, and filterBank
	
	properties (Access = protected)
		Amat
		Smat
	end
	
	methods
		% Constructor.
		function obj = FourPort(matInit,inType,doSimp)
			if nargin ~= 0
				if nargin < 2
					inType = 'Smat';
				end
				if nargin < 3
					doSimp = true;
				end
				switch inType
					case 'Smat'
						obj.Smat = matInit;
						obj.Amat = FourPort.StoA(matInit,doSimp);
					case 'Amat'
						obj.Amat = matInit;
						obj.Smat = FourPort.AtoS(matInit,doSimp);
				end
			end
		end
		
		function Smat = getS(obj)
			Smat = obj.Smat;
		end
		
		% swaps the object's ports 2 and 3
		function swivel(obj)
			p23 = [1 3 2 4];
			newS(p23,p23) = obj.Smat;
			obj.Smat = newS;
			obj.Amat = FourPort.StoA(newS);
		end
		
		% returns an optimized matlab function representing transmission
		% between the ports in the argument. Power transmission
		function eq6Fun = genTransFun(obj,inPort,outPort)
			powTrEl = abs(obj.Smat(inPort,outPort))^2;
			eq6Fun = matlabFunction(powTrEl,'Vars',symvar(powTrEl));
		end
	end
	
	methods (Static)
		function Smat = AtoS(Amat,doSimp)
			if nargin < 2
				doSimp = true;
			end
			p23 = [1 3 2 4];
			Tmat(p23,p23) = Amat;
			TA = Tmat(1:2,1:2);
			TB = Tmat(1:2,3:4);
			TC = Tmat(3:4,1:2);
			TD = Tmat(3:4,3:4);
			TAinv = TA^-1;
			
			Smat = [TC*TAinv,   TD - TC*TAinv*TB; ...
				TAinv   ,   -TAinv*TB];
			if isa(Smat,'sym') && doSimp
				Smat = simplify(Smat,'IgnoreAnalyticConstraints',true);
			end
		end
		
		function Amat = StoA(Smat,doSimp)
			if nargin < 2
				doSimp = true;
			end
			SA = Smat(1:2,1:2);
			SB = Smat(1:2,3:4);
			SC = Smat(3:4,1:2);
			SD = Smat(3:4,3:4);
			SCinv = SC^-1;
			
			Tmat = [SCinv   ,   -SCinv*SD; ...
				SA*SCinv,   SB - SA*SCinv*SD];
			p23 = [1 3 2 4];
			Amat(p23,p23) = Tmat;
			if isa(Amat,'sym') && doSimp
				Amat = simplify(Amat,'IgnoreAnalyticConstraints',true);
			end
		end
		
		% the argument can be an array of four ports, or a list of
		% arguments that are each four port objects
		% returns a new four port to represent the composition
		function fPout = join(varargin)
			if islogical(varargin{end})
				% caller has specified whether to simplify
				doSimp = varargin{end};
				varargin = varargin(1:end-1);
			else
				doSimp = true;
			end
			aBuilder = eye(size(varargin{1}(1).Amat,1));
			for iArg = 1:length(varargin)
				for iArr = 1:length(varargin{iArg})
					thisA = varargin{iArg}(iArr).Amat;
					aBuilder = aBuilder * thisA;
				end
			end
			fPout = FourPort(aBuilder,'Amat',doSimp);
		end
		
		function fPout = waveguide(Leff,alph)
			if nargin < 2
				alph = 0;
			end
			Lclean = [Leff(1), Leff(end)];
			syms s imag
			wtf = exp(-(alph + s) .* Lclean);
			SmatInit = [zeros(2), diag([wtf(1),wtf(2)]); ...
				diag([wtf(1),wtf(2)]), zeros(2)];
			fPout = FourPort(SmatInit);
		end
		
		% type determines which ports are coupled to one another
		% type 1: port 1 couples to 3 and 4
		% type 2: port 1 couples to 2 and 3
		% type 3: port 1 couples to 2 and 4
		% This coupler model is lossless.
		function fPout = coupler(type,K)
			a = 1;
			coup = a * [sqrt(1-K), 1i*sqrt(K); 1i*sqrt(K), sqrt(1-K)];
			Stype1 = [zeros(2), coup; coup, zeros(2)];
			switch type
				case 1
					SmatInit = Stype1;
				case 2
					p24 = [1 4 3 2];
					SmatInit(p24,p24) = Stype1;
				case 3
					p23 = [1 3 2 4];
					SmatInit(p23,p23) = Stype1;
			end
			fPout = FourPort(SmatInit);
		end
		
		function fPout = mrrFilter(coupArr,lenArr)
			M = length(lenArr);
			if length(coupArr) < M+1
				coupArr = coupArr(1) * ones(M+1,1);
			end
			ringArr = FourPort.coupler(3,coupArr(1));
			for iRing = 1:length(lenArr)
				ringArr(end+1) = FourPort.waveguide(pi*lenArr(iRing));
				ringArr(end+1) = FourPort.coupler(3,coupArr(iRing+1));
			end
			disp(['Creating filter: coupArr=', char(sym(coupArr)), ', lenArr=', char(sym(lenArr))]);
			fprintf('Joining rings...')
			fPout = FourPort.join(ringArr,true);
			fPout.swivel;
			disp('Completed.')
		end
		
		% make sure they're in the right dimension
		% each column corresponds to one of N filters
		% This is limited to the same number of rings per filter, but
		% doesn't necessarily need to be
		function fPout = filterBank(coupMat,lenMat,busArr)
			[M,N] = size(lenMat);
			if size(coupMat,1) == 1
				coupMat = repmat(coupMat,M+1,1);
			end
			if size(coupMat,2) == 1
				coupMat = repmat(coupMat,1,N);
			end
			if size(busArr,1) == 1
				busArr = repmat(busArr,2,1);
			end
			if size(busArr,2) == 1
				busArr = repmat(busArr,1,N-1);
			end
			assert(all(size(coupMat) - size(lenMat) == [1,0]));
			assert(size(busArr,2) - size(lenMat,2) == -1);
			for iFilt = 1:N
				filtArr(2*(iFilt-1)+1) = FourPort.mrrFilter(coupMat(:,iFilt),lenMat(:,iFilt));
				if iFilt ~= N
					filtArr(2*(iFilt-1)+2) = FourPort.waveguide(busArr(:,iFilt));
				end
			end
			disp(['Creating filter bank: busArr=', char(sym(busArr))]);
			fprintf('Joining filters...')
			fPout = FourPort.join(filtArr,false);
			disp('Completed.')
		end
	end
	
end

