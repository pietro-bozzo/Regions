function fig = plotAvalanches(this,start,stop,opt)
% plotAvalanches Plot spike avalanches over time for each region

arguments
  this (1,1) regions
  start (1,1) double {mustBeNonnegative} = 0
  stop (1,1) double {mustBeNonnegative} = 0
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.scale (1,1) double {mustBeNonnegative} = 200000 % parameter to control height of each plot such that ylim = [0,scale]
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = true
end

% find requested states and regions
[s_indeces,r_indeces,opt.states,opt.regions] = this.indeces(opt.states,opt.regions);

% make figure
fig = figure(Name='aval',NumberTitle='off',Position=get(0,'Screensize')); hold on
title("Avalanches for "+this.printBasename()+', w: '+num2str(this.aval_window)+', s: '+num2str(this.aval_smooth)+', t: '+num2str(this.aval_threshold));

% loop over states and regions
max_stop = stop;
for s = 1 : numel(s_indeces)
  state = this.states(s_indeces(s));
  for r = 1 : numel(r_indeces)
    % get avalanches
    intervals = this.avalIntervals(state,this.ids(r_indeces(r)));
    sizes = this.avalSizes(state,this.ids(r_indeces(r)));
    if stop <= 0
      stop = -intervals(end,1) - 0.001;
      max_stop = max([max_stop,abs(stop)]);
    end
    % keep traces in requested time
    ind = intervals(:,1) > start & intervals(:,1) < abs(stop);
    intervals = intervals(ind,:);
    sizes = sizes(ind);
    % adjust traces
    intervals = [intervals(:,1) - this.aval_window,intervals(:,1),intervals(:,1) + this.aval_window].'; % set x axis for plot, ignore avalanche duration (i.e., intervals(:,2))
    sizes = [zeros(size(sizes)),sizes,zeros(size(sizes))].'; % pad with zeros for visualization
    intervals = intervals(:); % flatten
    sizes = sizes(:) + opt.scale * (r-1); % flatten and adjust heights not to overlap traces
    % set appearance of line in legend
    if r == 1, handle = 'on'; else, handle = 'off'; end
    % plot avalanches
    plot(intervals,sizes,Color=myColors(s),DisplayName=state,HandleVisibility=handle);
  end
end

% make labels
ticks = opt.scale / 2 * (0 : 2*numel(r_indeces));
labels = regionID2Acr(opt.regions) + '\newlinen: ' + string(this.nNeurons(opt.regions)); % label is region acronym + number of neurons
labels = [repmat("",size(r_indeces.')),labels].';
labels = [labels(:);""];

% adjust plot
adjustAxes(gca,'XLim',[start;max_stop],'YLim',[0.5,ticks(end)],'YTick',ticks,'YTickLabel',labels)
xlabel('time (s)');
ylabel('size (a.u.)');
legend()

if opt.save
  %saveas(fig,append(this.results_path,'/raster.',string(this.ids(i)),'.svg'),'svg')
end
if ~opt.show
  close(fig)
end