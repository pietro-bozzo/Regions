function fig = plotAvalanches(this,start,stop,step,opt)
% plotAvalanches Plot spike avalanches over time for each region

arguments
  this (1,1) regions
  start (1,1) {mustBeNumeric,mustBeNonnegative} = 0
  stop (1,1) {mustBeNumeric,mustBeNonnegative} = 0
  step (1,1) {mustBeNumeric,mustBeNonnegative} = 0
  opt.states (:,1) string = []
  opt.regions (:,1) {mustBeNumeric,mustBeInteger} = []
  opt.scale (1,1) {mustBeNumeric,mustBeNonnegative} = 200000 % parameter to control height of each plot such that ylim = [0,scale]
end

% find requested states and regions
[s_indeces,r_indeces,opt.states,opt.regions] = this.indeces(opt.states,opt.regions,rearrange=true);

% make figure
tit = "Avalanches for "+this.printBasename()+', w: '+num2str(this.aval_window)+', s: '+num2str(this.aval_smooth)+', t: '+num2str(this.aval_threshold);
if step ~= 0, tit = tit + ', b: ' + num2str(step) + ' s'; end
fig = makeFigure('aval',tit);

% loop over states and regions
max_stop = stop;
state_traces = cell(numel(s_indeces),numel(r_indeces));
times = cell(numel(s_indeces),numel(r_indeces));
for s = 1 : numel(s_indeces)
  state = this.states(s_indeces(s));
  for r = 1 : numel(r_indeces)
    % get avalanches
    [sizes,intervals] = this.avalSizes(state,this.ids(r_indeces(r)),nan_pad= step==0);
    if stop <= 0
      %real_stops = intervals(~isnan(intervals(:,2)),2);
      %stop = -real_stops(end) - 0.001;
      stop = -intervals(end,2) - 0.001;
      max_stop = max([max_stop,abs(stop)]);
    end
    % keep traces in requested time
    ind = intervals(:,1) > start & intervals(:,1) < abs(stop);
    intervals = intervals(ind,:);
    sizes = sizes(ind);
    if step == 0
      % adjust traces to plot single avalanches
      intervals = [intervals(:,1),(intervals(:,1)+intervals(:,2))/2,intervals(:,2);NaN,NaN,NaN].'; % set x axis, centering each point in an avalanche
      sizes = [zeros(size(sizes)),sizes,zeros(size(sizes));NaN,NaN,NaN].'; % pad with zeros each point, add NaNs between each region
      sizes([1,3],isnan(sizes(2,:))) = NaN;
      intervals = intervals(:); % flatten
      sizes = sizes(:) + opt.scale * (r-1); % flatten and adjust heights not to overlap traces
    else
      % bin over time
      bin_ind = ceil((intervals(:,1)-start)/step);
      bin_ind(bin_ind==0) = 1;
      sizes = [accumarray(bin_ind,sizes);NaN] + opt.scale * (r-1);
      intervals = [((start+step/2) : step : step*bin_ind(end)).'; NaN];
    end
    state_traces{s,r} = sizes;
    times{s,r} = intervals;
  end
end

% plot traces
for s = 1 : numel(s_indeces)
  plot(vertcat(times{s,:}),vertcat(state_traces{s,:}),Color=myColors(s,'IBMcb'),LineWidth=1.64,DisplayName=this.states(s_indeces(s)));
end

% make left axis labels
ticks = opt.scale / 2 * (0 : 2*numel(r_indeces));
labels = regionID2Acr(opt.regions) + '\newlinen: ' + string(this.nNeurons(opt.regions)); % label is region acronym + number of neurons
labels = [repmat("",size(r_indeces.')),labels].';
labels = [labels(:);""];

% adjust plot
adjustAxes(gca,'XLim',[start;max_stop],'YLim',[0.5,ticks(end)],'YTick',ticks,'YTickLabel',labels)
xlabel('time (s)');
ylabel('regions');
legend()

lax = gca;
% make right axis
axes(Position=[lax.Position(1:3),lax.Position(4)/numel(r_indeces)],XColor='none',Color='none',YAxisLocation='right')
adjustAxes(gca,'YLim',[0,opt.scale-1],'Color',missing,'XColor',missing)
ylabel('size (a.u.)');
linkaxes([lax,gca])
% reset main axes
axes(lax);