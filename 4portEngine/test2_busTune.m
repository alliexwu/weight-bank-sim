% test2_bus2pole.m
% Look at the effect of bus length difference with 2-pole filters.
% This example uses two parameters: dl and off
% dl describes the length difference of the bus waveguides
% try changing this to see what plots are available
plotType = 2;

% filter order (make sure to clear workspace if you decide to refresh this)
M = 1;

if ~exist('testBank','var') % only initialize if the object doesn't exist
	syms dl off
	ringOffs = repmat([0, off],M,1); % Ring 1 is fixed at 0. Ring 2 is parameterized by off
	busLen = [1+dl; 1];  % bus WG uses variable dl twice (note: it's a column vector)
	coup = [.3; repmat(.03,M-1,1); .3];    % central coupling coefficient different than bus coupling coefficients
	defParam = [0, .1, 0];  % corresponds to defaults for [dl1, dl2, off, s]
	testBank = Bank.init(coup,ringOffs,busLen,defParam);
	testBank.sigProbes = [0, .1];
	clear ringOffs busLen coup defParam
end

switch plotType
	case 1
		testBank.params(1).sweep = linspace(-.1,.1,300);
		testBank.plotSpect;
		testBank.clearSweeps;
	case 2
		testBank.params(2).sweep = linspace(-.3,.3,500);
		testBank.params(1).default = 0;
		testBank.plotSpect;
		figure
		testBank.params(1).default = pi/testBank.ord;
		testBank.plotSpect;
		testBank.clearSweeps;
end
		