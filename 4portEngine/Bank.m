% This class serves as a wrapper for the FourPort model of a filter bank.
% It provides various plotting and analysis options, specific to filter
% banks.
% Use constructor to wrap an existing model. Use static Bank.init to also
% initialize the model.

% A Bank object contains
% 1) a FourPort model of drop and thru functions
% 2) resonance order, which has to do with frequency normalization
%    -frequency is normalized so peaks fall on integers and 0
%    normalized frequency is the resonance closest to 1550 nm.
% 3) sigProbes: the normalized frequencies where input signals are
% centered. The Weight is just the (thru-drop) transmission at these points.
% 4) params: structure of parameters in the model with fields:
%    -name, the name token used in the symbolic model
%    -default, a standard scalar value for this particular parameter
%    -sweep, a scalar or array of values. If array, this is
%    considered an active parameter that can take on all the sweep
%    values while plotting

classdef Bank < handle
    properties
		drop
		thru
		ord
		sigProbes
		params
	end
    
    methods
		% It is generally better to initialize using the Bank.init method
        function obj = Bank(model,l0,M,sigProbes,defParams)
            if nargin ~= 0
				fprintf('Optimizing...')
                obj.thru = model.genTransFun(1,3);
				if mod(M,2) == 0
					obj.drop = model.genTransFun(1,4);
				else
					obj.drop = model.genTransFun(1,2);
				end
				disp('Complete.')
				
				obj.ord = Bank.calcOrd(l0);
				obj.sigProbes = sigProbes;
				
				str = func2str(obj.drop); %// get fun's defining string
				str = regexp(str, '^@\([^\)]+\)', 'match'); %// keep only "@(...)" part
				vars = regexp(str{1}(3:end-1), ',', 'split'); %// remove "@(" and ")", and  split by commas
				for iP = 1:length(vars)
					%if strcmp(vars{iP},'s'), continue; end
					obj.params(iP).name = vars{iP};
					if nargin < 5, defParams(iP) = 0; end
					obj.params(iP).default = defParams(iP);
					obj.params(iP).sweep = defParams(iP);
				end
			else % script for tests, default behavior
				syms h1 h2 h3 real
				obj=Bank.init([.3,h1,.3;.3,.3,.3],[-h2,0,h2],[h3,h3],[.3,.1,0,0]);
				obj.plotSpect;
			end
		end
		
		function plotSpect(obj)
			activeInds = obj.activeParams;
			dims = length(activeInds);
			if dims > 1
				disp('Too many active parameters. Max is 1 at a time.');
			end
			omNum = linspace(-1,1,500);
			argCell = {obj.params.default};
			argCell{obj.omParam} = 1i*(omNum + obj.ord);

			if dims == 0
				plot(omNum,obj.drop(argCell{:}),omNum,obj.thru(argCell{:}));
				xlabel('omega');
				ylabel('transmission');
			else
				pvals = obj.params(activeInds(1)).sweep;
				[OM,P] = meshgrid(omNum,pvals);
				argCell{obj.omParam} = 1i*(OM + obj.ord);
				argCell = obj.setSweepVals(argCell,{P});
				surf(omNum,pvals,obj.drop(argCell{:}),'linestyle','none');
				xlabel('omega');
				ylabel(obj.params(activeInds(1)).name);
			end
		end
		
		function argCell = setSweepVals(obj,argCell,paramSweepCell)
			activeInds = obj.activeParams;
			for iAP = 1:length(paramSweepCell)
				activeName = obj.params(activeInds(iAP)).name;
				% set values of the sweeping parameter
				argCell{activeInds(iAP)} = paramSweepCell{iAP};
				% set the other parameters whose defaults depend on this
				% sweeping parameters.
				% This should work, but currently doesn't, so it throws an
				% error instead
				for iP = 1:length(obj.params)
					if isa(argCell{iP},'sym')
						error('Defaults that depend on other parameters are not currently supported.')
						if any(symvar(argCell{iP}) == activeName)
							eq6Fun = matlabFunction(argCell{iP},'Vars',activeName);
							argCell{iP} = eq6Fun(paramSweepCell{iAP});
						end
					end
				end
			end
		end
		
		function plotWeight(obj)
			activeInds = obj.activeParams;
			dims = length(activeInds);
			if dims < 1
				disp('Need to specify at least on parameter to plotSlice');
				return
			elseif dims > 2
				disp('Too many active parameters. Max is 2 at a time.');
				return
			end
			argCell = {obj.params.default};
			chanCnt = length(obj.sigProbes);
			cla; hold on
			if dims == 1
				pval = obj.params(activeInds(1)).sweep;
				argCell = obj.setSweepVals(argCell,{pval});
				for ich = 1:chanCnt
					argCell{obj.omParam} = 1i*(obj.sigProbes(ich) + obj.ord);
					plot(pval,obj.weight(argCell{:}));
				end
				xlabel(obj.params(activeInds(1)).name);
				ylabel('Weight');
			elseif dims == 2
				p1val = obj.params(activeInds(1)).sweep;
				p2val = obj.params(activeInds(2)).sweep;
				[P1,P2] = meshgrid(p1val,p2val);
				argCell = obj.setSweepVals(argCell,{P1,P2});
				for ich = 1:chanCnt
					subplot(1,chanCnt,ich)
					argCell{obj.omParam} = 1i*(obj.sigProbes(ich) + obj.ord);
					surf(p1val,p2val,obj.weight(argCell{:}),'linestyle','none');
					xlabel(obj.params(activeInds(1)).name);
					ylabel(obj.params(activeInds(2)).name);
					title(['Weight ', num2str(ich)]);
				end
			end
		end
		
		function clearSweeps(obj)
			for iP = 1:length(obj.params)
				obj.params(iP).sweep = obj.params(iP).default;
			end
		end
		
		function dat = weight(obj,varargin)
			dat = obj.thru(varargin{:}) - obj.drop(varargin{:});
		end
		
		function inds = activeParams(obj)
			inds = [];
			for iP = 1:length(obj.params)
				if ~strcmp(obj.params(iP).name,'s')
					if length(obj.params(iP).sweep) > 1
						inds(end+1) = iP;
					end
				end
			end
		end
		
		function ind = omParam(obj)
			for iP = 1:length(obj.params)
				if strcmp(obj.params(iP).name,'s')
					ind = iP;
				end
			end
		end
    end
    
    methods (Static)
        % constructor that initializes its child model
		
		% offMat (M x N) is in terms of frequency offset (in FSR units) from 0
		% each column corresponds to a mrrFilter, rows correspond to rings
		% within each filter.
		
		% coupMat (M+1 x N) is the coupling coefficients within each filter
		% If coupMat has singleton dimensions, it will be repeated
		
		% busArr (2 x N-1) is the bus WG lengths in FSR units
		% If busArr has singleton dimensions, it will be repeated
		
		% defParams are default values for symbolic parameters and symbolic
		% s, in alphabetic order. For example, if the model expression has
		% symbolic variables h3,h1,s, and h2, then
		% defParams=[1.0, 2.0, -1.0, 0.0] will set defaults to:
		% h1 = 1.0;    h2 = 2.0;   h3 = -1.0;   s = 0.0
		% The s (frequency) value doesn't matter and is unused.
		function obj = init(coupMat,offMat,busArr,defParams)
			l0default = 20e-6;
			lenMat = Bank.offs2lens(Bank.calcOrd(l0default),offMat);
			bankModel = FourPort.filterBank(coupMat,lenMat,busArr);
			[M,N] = size(lenMat);
			obj = Bank(bankModel,l0default,M,linspace(0,.5,N),defParams);
		end
		
		function ord = calcOrd(l0)
			n = 4.2;
			c = 3e8;
			nomLam = 1.550e-6;
			
			fsr = 2*pi*c/n/l0;
			nomOmeg = c * 2 * pi / nomLam;
			ord = round(nomOmeg / fsr);
		end
		
		%converts a matrix off desired fsr offsets into a matrix of lengths
		function lens = offs2lens(ord,offs)
			lens = ord./(ord+offs);
		end
    end
end %classdef