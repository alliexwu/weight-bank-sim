function [ze,po] = testerScratch(guessZe,guessPo)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%clear
close all

% z = zeros(2);
% %K = .2;
% %a = 1;
% K = sym('K');
% a = sym('a');
% coup = a * [sqrt(1-K), 1i*sqrt(K); 1i*sqrt(K), sqrt(1-K)];
% sType1 = [z, coup; coup, z];
% p23 = [1 3 2 4];
% sType5(p23,p23) = sType1;
% StoA(sType5);


c=3;
n=3.45;
len = 8;
r = sqrt(.95);
t = sqrt(1 - r^2);

% it would be good to represent the structure of the network someway,
% before introducing the LTI models. They don't like being in A
% matrices due to the non-causality. The structure doesn't change with
% tuning though, so that would be nice to precompute.
% This is possible: just use exp along the way. In the end for the
% final expression, redefine s as tf. m=eval(char(sym)) will convert
% your symbolic network to a state-space model. Then you can use
% tf(pade(m,8)) to get rational appx.

% what about doing a fixed phase shift to approximate a delay? Given
% that the center frequency is so high, very small changes in slope,
% i.e. delay, will have little effect on the slope, while changing the
% phase considerably.

% it appears generalized parameters are incompatible with delays
% but keeping the algebraic expression with tuning symbolic variables,
% then substituting real ones might work.

s = sym('s');
T = sym('T');
h = sym('h');
syms om real
delAbs = symfun(sym('del(T)'),T);
%myPade = symfun(sym('myPade'),[]);
delExp = @(x) exp(-s*x);
%	delPad = myPade(T);

[num,den] = pade(1,1);
syms myPade
myPade = @(x) poly2sym(num,s*x) ./ poly2sym(den,s*x);
del = {delAbs,@exp,myPade};

if 0
	s = sym('s');
	om = sym('om');
	%omegas = 2e13*(0:.001:1);
	
	
	Swg = initWG(len/2,0,n,s);
	Awg = StoA(Swg);
	Awg2 = StoA(initWG(1.0*len/2,0,n,s));
	Sco = initCoupler(3,t^2,1);
	Aco = StoA(Sco);
	Amrr = (Aco * Awg)^1 * Aco;% * Awg2 * Aco;
	Smrr = AtoS(Amrr);
	SmrrTilde(p23,p23) = Smrr;
	
	dro = SmrrTilde(2,1);
	thru = SmrrTilde(3,1);
	%dro=thru;
	
	fsr = 2*pi*c/n/len;
	omegas = (10.5+(0:.001:2))*fsr;
	
	droM = subs(dro,'s',1i*om);
	simpDro = -t^2 * exp(-1i*omegas*n/c*len/2) ./ (1 - r^2 * exp(-1i*omegas*n/c*len));
	simpDroSq = t^4 ./ (1 - 2*r^2*cos(omegas*n/c*len) + r^4);
	droNumeric = subs(vpa(droM),'om',omegas);
	%plot(omegas,10*log10(abs(simpDro).^2),omegas,10*log10(abs(droNumeric).^2));
	
	[n,d] = numden(dro);
	ran = [min(omegas),max(omegas)];
	if nargin < 2
		ze = mySolvePerioCmpl(n,ran);
		po = mySolvePerioCmpl(d,ran);
	else
		ze = mySolveVPA(n,guessZe);
		po = mySolveVPA(d,guessPo);
	end
	
	figure
	cplotSym(dro,ran)
	
	figure
	subplot(1,2,2)
	plot(10*log10(abs(droNumeric).^2),omegas)
	set(gca,'YaxisLocation','right')
	yuse = ylim;
	subplot(1,2,1)
	plot(real(po),imag(po),'kx',real(ze),imag(ze),'ko')
	currentX = xlim;
	%xlim([2*currentX(1), 0]);
	ylim(yuse);
elseif 0
	s = sym('s');
	Swg = initWG(len/2,0,n,s);
	Awg = StoA(Swg);
	Sco = initCoupler(3,t^2,1);
	Aco = StoA(Sco);
	Amrr = (Aco * Awg)^1 * Aco;% * Awg2 * Aco;
	Smrr = AtoS(Amrr);
	SmrrTilde(p23,p23) = Smrr;
	s = ss('s');
	tr = SmrrTilde(1,2);
	h = eval(tr);
else
	fsr = 2*pi*c/n/len;
	
	Swg = initWGsym(len/2,0,n);
	Awg = StoA(Swg);
	Awg2 = StoA(initWGsym(.99*len/2*(1+h),0,n));
	Awgh = StoA(initWGsym(0.995*len*(1+h*[-1,1]),0,n));
	Sco = initCoupler(3,t^2,1);
	Scot = initCoupler(3,h,1);
	Aco = StoA(Sco);
	Acot = StoA(Scot);
	Acom = StoA(initCoupler(3,.03*t^2,1));
	Smrr1 = AtoS((Aco * Awg)^1 * Acom * Awg * Aco);
	Smrr2 = AtoS((Aco * Awg2)^1 * Acom * Awg2 * Aco);
	SmrrTilde1(p23,p23) = simplify(Smrr1);
	SmrrTilde2(p23,p23) = simplify(Smrr2);
	Atot = StoA(SmrrTilde1) * Awg * StoA(SmrrTilde2);
	SmrrTilde = AtoS(Atot);
	tr = simplify(SmrrTilde(4,1));
	%trPad = subs(SmrrTilde,'del','myPade');
	%SmrrTilde = subs(SmrrTilde,'h',0);
	trExp = eval(subs(tr,'del','delExp'));
	trExp = vpa(combine(trExp,'exp'));
	dro = vpa(subs(trExp,'s',1i*om));
	eq6fun = matlabFunction(dro,'Vars',[om h]);
	
	if 1
		%om = sym('om');
		omegas = (2.5+(0:.001:1))*fsr;
		%hs = .04+.02*fliplr(-100:100)/100;
		hs = -.1:.003:.1;
		hold on
		cmap = colormap(parula(length(hs)));
		for ihs = 1:length(hs)
			droNumeric = eq6fun(omegas,hs(ihs));
			plot(omegas,10*log10(abs(droNumeric).^2),'color',[cmap(ihs,:), .1]);
			drawnow;
			%pause(.02)
		end
		return
	end
	
	trPad = simplify(eval(subs(tr,'del','myPade')));
	%trDrop = eval(exp(4.37*s) * simplifyFraction(expand(simplify(vpa(trExp)))));
	%trDrop = subs(trDrop,'s',-s);
	modPad = sym2tf(eval(trPad));
	s = tf('s');
	%h = realp('h',0);
	%modExp = eval(char(trExp));
	%bode(modPad(2:3,1))
	
	opts = bodeoptions;
	opts.FreqScale = 'linear';
	opts.XLim = 1.5*fsr + fsr*[-.2, 6.2];
	bode(modExp,opts)
	figure
	bode(pade(modExp,8),opts)
end

	function tfobj = sym2tf(symExp)
		[numer,denom] = numden(symExp);
		for ii = 1:size(symExp,1)
			for jj = 1:size(symExp,2)
				np = sym2poly(numer(ii,jj));
				dp = sym2poly(denom(ii,jj));
				tfobj(ii,jj) = tf(np,dp);
			end
		end
	end

	function cplotSym(symExp,range)
		useXvals = linspace(range(1),range(2),20);
		[sigm,omeg] = meshgrid(useXvals);
		useSgrid = sigm + 1i*omeg;
		zdat = eval(vpa(subs(symExp,s,useSgrid)));
		surf(10*log10(abs(zdat)));
	end

	function roots = mySolveVPA(symExp,guesses)
		roots = zeros(size(guesses));
		for ii = 1:length(guesses)
			roots(ii) = vpasolve(symExp==0, s, guesses(ii));
		end
	end

	function roots = mySolvePerioCmpl(symExp,range)
		S = solve(symExp==0, s, 'ReturnConditions', true);
		if ~isempty(S.parameters)
			for ii = 1:size(S.s,1)
				assume(S.conditions(ii));
				solPvals = solve(imag(S.s(ii))>range(1), imag(S.s(ii))<range(2), S.parameters);
				newBranch = subs(S.s, S.parameters, solPvals);
				if ii==1
					roots = newBranch;
				else
					roots = [roots; newBranch];
				end
			end
		else
			roots = S.s;
		end
	end

	function Smat = initWG(L,alph,n,s)
		ex = (alph + n/c * s);
		Lclean = [L(1), L(end)];
		efun = @(x,m) exp(-x*Lclean(m));
		%efun = @(x) 1 + x + x.^2/2 + x.^3/6;
		%efun = @(x) taylorExp(x,3);
		%efun = @(x,m) exp(-alph*Lclean(m)) * poly2sym(pade(n/c*Lclean(m),5),x);
		%sca1 = efun(-ex*Lclean(1));
		%sca2 = efun(-ex*Lclean(2));
		sca1 = efun(s,1);
		sca2 = efun(s,2);
		Smat(1,3) = sca1;
		Smat(3,1) = sca1;
		Smat(2,4) = sca2;
		Smat(4,2) = sca2;
	end

	function Smat = initWGinZ(N,L0,alph,n,z)
		Nclean = [N(1), N(end)];
		atten = exp(-alph*Nclean*L0);
		sca1 = atten(1) * z.^-Nclean(1);
		sca2 = atten(2) * z.^-Nclean(2);
		Smat(1,3) = sca1;
		Smat(3,1) = sca1;
		Smat(2,4) = sca2;
		Smat(4,2) = sca2;
	end

	function Smat = initWGtf(L,alph,n)
		Lclean = [L(1), L(end)];
		s = tf('s');
		w1tf = exp(-alph*Lclean(1)) * exp(-n/c*Lclean(1)*s);
		w2tf = exp(-alph*Lclean(2)) * exp(-n/c*Lclean(2)*s);
		Smat = [zeros(2), w1tf * eye(2); w2tf * eye(2), zeros(2)];
	end

	function Smat = initWGsym(L,alph,n)
		Lclean = [L(1), L(end)];
		%del = symfun(sym('f(s)'),[s]);
		w1tf = exp(-alph*Lclean(1)) * del{1}(n/c*Lclean(1));
		w2tf = exp(-alph*Lclean(2)) * del{1}(n/c*Lclean(2));
		Smat = [zeros(2), diag([w1tf,w2tf]); diag([w1tf,w2tf]) * eye(2), zeros(2)];
	end

	function y = taylorExp(x,N)
		y = 1;
		for i = 1:N
			y = y + x.^i/factorial(i);
		end
	end

	function Smat = initCoupler(type,K,a)
		z = zeros(2);
		coup = a * [sqrt(1-K), 1i*sqrt(K); 1i*sqrt(K), sqrt(1-K)];
		Stype1 = [z, coup; coup, z];
		switch type
			case 1
				Smat = Stype1;
			case 2
				p24 = [1 4 3 2];
				Smat(p24,p24) = Stype1;
			case 3
				p23 = [1 3 2 4];
				Smat(p23,p23) = Stype1;
		end
	end

	function Smat = AtoS(Amat)
		p23 = [1 3 2 4];
		Tmat(p23,p23) = Amat;
		TA = Tmat(1:2,1:2);
		TB = Tmat(1:2,3:4);
		TC = Tmat(3:4,1:2);
		TD = Tmat(3:4,3:4);
		TAinv = TA^-1;
		
		Smat = [TC*TAinv,   TD - TC*TAinv*TB; ...
			TAinv   ,   -TAinv*TB];
		if isa(Smat,'sym')
			Smat = simplify(Smat);
		end
	end

	function Amat = StoA(Smat)
		SA = Smat(1:2,1:2);
		SB = Smat(1:2,3:4);
		SC = Smat(3:4,1:2);
		SD = Smat(3:4,3:4);
		SCinv = SC^-1;
		
		Tmat = [SCinv   ,   -SCinv*SD; ...
			SA*SCinv,   SB - SA*SCinv*SD];
		p23 = [1 3 2 4];
		Amat(p23,p23) = Tmat;
		if isa(Amat,'sym')
			Amat = simplify(Amat);
		end
	end
end