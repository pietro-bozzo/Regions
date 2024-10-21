function plotICRaster(this,start,time_bin,stop,opt)
% plotICRaster Compute Avalanche Transition Matrix using IC activity from each region

arguments
  this (1,1) regions
  start (1,1) double {mustBeNonnegative}
  time_bin (1,1) double {mustBeNonnegative} % NOT IMPLEMENTED
  stop (1,1) double {mustBeNonnegative} % EMPROVE WHEN INPUT IS ZERO
  opt.states (:,1) string = []
  opt.avals (1,1) {mustBeLogical} = false
  opt.aval_thresh (1,1) double {mustBeNonnegative} = 0
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = false
end

% find requested states and regions
[j_indeces,~,opt.states] = this.getIndeces(opt.states);
% plot figures
for j = 1 : numel(j_indeces)
  brain = this.brain_array(j_indeces(j));
  if isempty(brain.ICs_binar_activity)
    error('plotICRaster:MissingBinActivity','Binarized activty was not computed.')
  end
  fig = figure(Name=append('raster_',opt.states(j)),NumberTitle='off',Position=get(0,'Screensize')); hold on
  [times,ICs] = find(brain.ICs_binar_activity);
  times_sec = times * brain.IC_window;
  if stop == 0
    stop = times_sec(end);
  end
  indeces = times_sec > start & times_sec < stop;

  % % reorder lines according to delay from time instant
  % t = start + (stop-start)/5;
  % unique_ICs = unique(ICs);
  % IC_delays = zeros(size(unique_ICs));
  % for i = 1 : numel(unique_ICs)
  %   IC_times = times_sec(ICs==unique_ICs(i));
  %   delays = IC_times(IC_times>t);
  %   IC_delays(i) = delays(1) - t;
  % end
  % [~,ind] = sort(IC_delays);
  % sorted_ICs = zeros(size(ICs));
  % for i = 1 : numel(ind)
  %   sorted_ICs(ICs==ind(i)) = i;
  % end
  % ICs = sorted_ICs;

  IClist = this.getIClist(opt.states(j));
  if opt.avals
    aval_intervals = brain.getAvalIntervals(restriction=[start;stop],threshold=opt.aval_thresh);
    plotIntervals(aval_intervals,color=[0.5,0.5,0.5],alpha=0.15,ylim=[0,sum(IClist)])
  end
  scatter(times_sec(indeces),ICs(indeces),6,'square','filled')
  % create y labels
  ticks = 0.5;
  labels = "";
  indeces = 1;
  for i = 1 : numel(IClist)
    ticks = [ticks;ticks(end)+IClist(i)/2;ticks(end)+IClist(i)];
    labels = [labels,regionID2Acr(this.ids(i)),""];
    indeces(end+1) = ticks(end) + 0.5;
  end
  % adjust plot
  set(gca,TickDir='out',XLim=[start;stop],YLim=[0,sum(IClist)],YTick=ticks,YTickLabel=labels)
  xlabel('time (s)',FontSize=14);
  ylabel('ICs',FontSize=14);
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