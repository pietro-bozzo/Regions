function fig = plotFiringRates(this,start,stop,opt)
% plotFiringRates Plot firing rate of each region

arguments
  this (1,1) regions
  start (1,1) double {mustBeNonnegative} = 0
  stop (1,1) double {mustBeNonnegative} = 0
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.smooth (1,1) double {mustBeNonnegative} = 2
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = true
end

% find requested states and regions
[s_indeces,r_indeces,opt.states] = this.indeces(opt.states,opt.regions);

% make figure
fig = figure(Name='firing_rate',NumberTitle='off',Position=get(0,'Screensize')); hold on
title(append('Firing rates for ',this.printBasename()),FontSize=17,FontWeight='Normal');

% loop over states and regions
max_stop = stop;
for s = 1 : numel(s_indeces)
  [state_firing,time] = this.firingRate(this.states(s_indeces(s)),this.ids(r_indeces),smooth=opt.smooth,nan_pad=true);
  if stop <= 0
    stop = -time(end) - 0.001;
    max_stop = max([max_stop,abs(stop)]);
  end
  % keep traces in requested time
  ind = time > start & time < abs(stop);
  state_firing = state_firing(ind,:);
  time = time(ind,:);
  % adjust traces
  time = repmat([time;NaN],size(state_firing,2),1);
  state_firing = state_firing + 500 * (0 : numel(r_indeces)-1); % adjust heights
  state_firing = [state_firing;NaN(1,size(state_firing,2))]; % break plotting between lines
  state_firing = state_firing(:); % flatten for plot
  % plot
  plot(time,state_firing,Color=myColors(s),DisplayName=this.states(s_indeces(s)));
end
% make labels
ticks = 250 * (0 : 2*numel(r_indeces));
labels = [repmat("",size(r_indeces.')),regionID2Acr(this.ids(r_indeces))].';
labels = [labels(:);""];
% adjust plot
adjustAxes(gca,'XLim',[start;max_stop],'YLim',[0.5,ticks(end)],'YTick',ticks,'YTickLabel',labels)
xlabel('time (s)');
ylabel('population firing rate (Hz)');
legend()

if opt.save
  %saveas(fig,append(this.results_path,'/raster.',string(this.ids(i)),'.svg'),'svg')
end
if ~opt.show
  close(fig)
end