session = '/mnt/cortex-data-311/Rat386-20180923/Rat386-20180923.xml';

spike_dt = 0.04;
threshold = 0.3;
phase = "sleep1";
states = ["sws";"rem";"awake"];
R = regions(session,phase=phase,states=states);
disp('loading');
R = R.loadSpikes();
disp('compute');
R = R.computeNetworkAval();