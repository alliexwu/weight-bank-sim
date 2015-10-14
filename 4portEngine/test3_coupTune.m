% test3_coupTune.m
% Using a tunable coupler

% try changing this to see what plots are available
plotType = 4;

if ~exist('testBank','var') % only initialize if the object doesn't exist
	syms co off
	ringOffs = [0, off]; % Ring 1 is fixed at 0. Ring 2 is parameterized by off
	busLen = 0;  % ignore bus WG propagation effect
	coup = [.3, co; .3, .3];    % put a variable for one of the couplers
	defParam = [.3, .2, 0];  % corresponds to defaults for [c, off, s]
	testBank = Bank.init(coup,ringOffs,busLen,defParam);
	testBank.sigProbes = [0, .2];
	clear ringOffs busLen coup defParam
end

switch plotType
	case 1
		testBank.plotSpect;
	case 2
		testBank.params(1).sweep = linspace(0,1,300);
		testBank.plotSpect;
		testBank.clearSweeps;
	case 3
		testBank.params(1).sweep = linspace(0,1,300);
		testBank.plotWeight;
		testBank.clearSweeps;
	case 4
		testBank.params(1).sweep = linspace(0,1,300);
		testBank.params(2).sweep = linspace(.1,.3,300);
		testBank.plotWeight;
		testBank.clearSweeps;
end
		