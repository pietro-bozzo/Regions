function fig = plotFiringRates(this,start,stop,step,opt)
% plotFiringRates Plot firing rate divided by regions, computed via gaussian smoothing of spike samples
%
% arguments:
%     start      double = 0, xlim will be [start,stop]
%     stop       double = 0, defaults to max spike time
%     step       double = 0, time bin in s, defaults to 0.05 or avalanche time window if avals = true
%
% name-value arguments:
%     states     (n_states,1) string = [], behavioral states, defaults to all states
%     regions    (n_regs,1) double = [], brain regions, defaults to all regions
%     smooth     double = [], gaussian kernel std in number of samples, defaults to 2 or avalanche smooth if avals = true
%     avals      logical = false, if true, plot avalanches
%
% output:
%     fig        figure

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  start (1,1) double {mustBeNonnegative} = 0
  stop (1,1) double {mustBeNonnegative} = 0
  step (1,1) double {mustBeNonnegative} = 0
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.smooth (:,1) double {mustBeNonnegative} = []
  opt.avals (1,1) {mustBeLogical} = false
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = true
end

% set default values
if opt.avals
  assert(this.hasAvalanches(),'plotFiringRates:MissingAvalanches','Avalanches haven''t been computed.')
  % default to same values used for avalanche detection
  if step == 0, step = this.aval_window; end
  if isempty(opt.smooth), opt.smooth = this.aval_smooth; end
else
  if step == 0, step = 0.05; end
  if isempty(opt.smooth), opt.smooth = 2; end
end

% find requested states and regions
[s_indeces,r_indeces,opt.states,opt.regions] = this.indeces(opt.states,opt.regions,rearrange=true);

% make figure
fig = figure(Name='firing_rate',NumberTitle='off',Position=get(0,'Screensize')); hold on
tit = "Firing rates for " + this.printBasename() + ', w: ' + num2str(step) + ' s, s: ' + num2str(opt.smooth);
if opt.avals, tit = tit + ', t: ' + num2str(this.aval_threshold); end
title(tit);
height = 500; % parameter to control height of each plot

% get traces to plot
max_stop = stop;
state_firing = cell(numel(s_indeces),1);
times = cell(numel(s_indeces),1);
for s = 1 : numel(s_indeces)
  [f_rate,time] = this.firingRate(this.states(s_indeces(s)),this.ids(r_indeces),window=step,smooth=opt.smooth,nan_pad=true);
  if stop <= 0
    stop = -time(end) - 0.001;
    max_stop = max([max_stop,abs(stop)]);
  end
  % keep traces in requested time
  ind = time >= start & time <= abs(stop);
  f_rate = f_rate(ind,:);
  time = time(ind);
  % adjust traces
  time = repmat([time;NaN],size(f_rate,2),1);
  f_rate = f_rate + height * (0 : numel(r_indeces)-1); % adjust heights
  f_rate = [f_rate;NaN(1,size(f_rate,2))]; % break plotting between lines
  f_rate = f_rate(:); % flatten for plot
  state_firing{s} = f_rate;
  times{s} = time;
end

% plot avalanches
if opt.avals
  % if 'all' is among states, just plot its avalanches
  s_aval = find(opt.states=='all');
  if isempty(s_aval)
    s_aval = s_indeces;
  end
  for s = s_aval
    for r = 1 : numel(opt.regions)
      aval_intervals = this.avalIntervals(this.states(s_indeces(s)),opt.regions(r),restriction=[start,max_stop]); % ,threshold=opt.aval_thresh
      PlotIntervals(aval_intervals-this.aval_window/2,'color',[0.5,0.5,0.5],'alpha',0.15,'ylim',[r-1,r]*height,'legend','off','bottom',false)
    end
  end
end

% plot firing rates
for s = 1 : numel(s_indeces)
  plot(times{s},state_firing{s},Color=myColors(s,'IBMcb'),DisplayName=this.states(s_indeces(s)));
end

% make labels
ticks = height / 2 * (0 : 2*numel(r_indeces));
labels = regionID2Acr(opt.regions) + '\newlinen: ' + string(this.nNeurons(opt.regions)); % label is region acronym + number of neurons
labels = [repmat("",size(r_indeces.')),labels].';
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