function plotICActivity(this,start,stop,ICs,opt)
% plotICActivity Compute Avalanche Transition Matrix using IC activity from each region

arguments
  this (1,1) regions
  start (1,1) double {mustBeNonnegative}
  stop (1,1) double {mustBeNonnegative} % EMPROVE WHEN INPUT IS ZERO
  ICs (:,1) double {mustBeInteger,mustBePositive}
  opt.zscore (1,1) {mustBeLogical} = true
  opt.states (:,1) string = []
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = false
end

% find requested states and regions
[j_indeces,~,opt.states] = this.getIndeces(opt.states);
% plot figures
for j = 1 : numel(j_indeces)
  brain = this.brain_array(j_indeces(j));
  if isempty(brain.ICs_activity)
    error('plotICRaster:MissingICA','ICA was not computed.')
  end
  fig = figure(Name=append('ICA_',opt.states(j)),NumberTitle='off',Position=get(0,'Screensize')); hold on
  activity = brain.ICs_activity;
  if opt.zscore
    activity = zscore(activity);
  end
  ind = brain.IC_time > start & brain.IC_time < stop;
  plot(brain.IC_time(ind),activity(ind,ICs)*10);
  legend(string(ICs))
  % adjust plot
  if stop == 0
    stop = brain.IC_time(end);
  end
  set(gca,TickDir='out',XLim=[start;stop])
  xlabel('time (s)',FontSize=14);
  ylabel('ICs reactivation',FontSize=14);
end
if opt.save
  %saveas(fig,append(this.results_path,'/raster.',string(this.ids(i)),'.svg'),'svg')
end
if ~opt.show
  if ~opt.save
    warning('Both options ''save'' and ''show'' were not selected.')
  end
  close(fig)
end