addpath /mnt/hubel-data-103/Pietro/Region_Aval/Code
addpath /mnt/hubel-data-103/Pietro/Single_Unit_Crit/Code
addpath /mnt/hubel-data-103/Pietro/Code/MATLAB/Personal
addpath /mnt/hubel-data-103/Pietro/Code/MATLAB/Regions/Helpers
addpath /mnt/hubel-data-103/Pietro/Code/MATLAB/Regions
addpath /mnt/hubel-data-103/Pietro/Code/MATLAB/ndSparse
addpath /mnt/hubel-data-103/Pietro/Code/MATLAB/ISAC
addpath /mnt/hubel-data-103/Pietro/Code/MATLAB/Violin
addpath /mnt/hubel-data-103/Pietro/Code/MATLAB
addpath /mnt/hubel-data-103/Pietro/Code
addpath /mnt/hubel-data-103/Marco/Code/basics
addpath /mnt/hubel-data-103/Marco/Code/FMAToolbox/Analyses
addpath /mnt/hubel-data-103/Marco/Code/FMAToolbox/Data
addpath /mnt/hubel-data-103/Marco/Code/FMAToolbox/General
addpath /mnt/hubel-data-103/Marco/Code/FMAToolbox/Helpers
addpath /mnt/hubel-data-103/Marco/Code/FMAToolbox/IO
addpath /mnt/hubel-data-103/Marco/Code/FMAToolbox/New
addpath	/mnt/hubel-data-103/Marco/Code/FMAToolbox/Plot
addpath /mnt/hubel-data-103/Marco/Code/xmltree
addpath /mnt/hubel-data-103/Marco/Code
addpath /mnt/hubel-data-103/ParisMarseille/celine_b/Projects/Fear/Matlab



session = '/mnt/cortex-data-311/Rat386-20180923/Rat386-20180923.xml';

spike_dt = 0.04;
threshold = 0.3;
phase = "sleep1";
states = ["sws";"rem";"awake"];
R = regions(session,phase=phase,states=states);
% load avalanches
%R = R.loadAval(spike_dt=opt.spike_dt);
% compute avalanches
disp('loading');
R = R.loadSpikes();
disp('compute');
R = R.computeNetworkAval();