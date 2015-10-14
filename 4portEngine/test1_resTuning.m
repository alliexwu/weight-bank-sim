% test1_resTuning.m
% Do a simple resonance tuning for a N=2, M=1 filter bank

% try changing this to see what plots are available
plotType = 2;

% filter order (make sure to clear workspace if you decide to refresh this)
M = 2;

if ~exist('testBank','var') % only initialize if the object doesn't exist
	syms h1
	ringOffs = [0, h1];  % Ring 1 is fixed at 0. Ring 2 is parameterized by h1
	busLen = 0;          % bus WG propagation effect is ignored
	coup = .2;           % all couplers will be .2 power transmission
	defParam = [.3, 0];  % corresponds to defaults for [h1,s]
	if M > 1
		ringOffs = repmat(ringOffs,M,1);
	end
	testBank = Bank.init(coup,ringOffs,busLen,defParam);
	testBank.sigProbes = [0, .2];
	clear ringOffs busLen coup defParam
end

switch plotType
	case 1
		testBank.plotSpect;
	case 2
		testBank.params(1).sweep = linspace(.1,.5,300);
		testBank.plotSpect;
		testBank.clearSweeps;
	case 3
		testBank.params(1).sweep = linspace(.1,.5,300);
		testBank.plotWeight;
		testBank.clearSweeps;
end
		