function [fig,h] = plotFiringRates(this,start,stop,window,opt)
% plotFiringRates Plot firing rate divided by regions, computed via gaussian smoothing of spike count
%
% arguments:
%     start      double = [], xlim will be [start,stop] in s, default is session beginnnig
%     stop       double = [], default is session end
%     window     double = 0.05, time bin in s
%
% name-value arguments:
%     states     (n_states,1) string = [], behavioral states, defaults to all states
%     regions    (n_regs,1) double = [], brain regions, defaults to all regions
%     step       double = 1, firing rates are computed in windows with overlap 'window' / 'step';
%                must be integer, default is no overlap
%     smooth     double = 1, gaussian kernel std in number of samples, default is no smoothing
%     mode       string, either:
%                  'fr'       :  population firing rate, default
%                  'fr_norm'  :  firing rate normalized by number of neurons per region
%                  'ratio'    :  ratio of active units
%     avals      logical = false, if true, plot avalanches (and change values of step, smooth, and
%                mode to match those used to compute avalanches)
%     scale      double, parameter to scale each region's plot
%     unit       string = 's', unit of time axis, either 's' or 'h'
%     ax         Axes = [], axes to plot on, default creates a new figure
%
% output:
%     fig        figure

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  start {mustBeScalarOrEmpty,mustBeNumeric} = []
  stop {mustBeScalarOrEmpty,mustBeNumeric} = []
  window (1,1) {mustBeNumeric,mustBePositive} = 0.05
  opt.states (:,1) string = []
  opt.regions (:,1) {mustBeNumeric,mustBeInteger} = []
  opt.step (1,1) {mustBeNumeric,mustBeInteger,mustBePositive} = 1
  opt.smooth (1,1) {mustBeNumeric,mustBePositive} = 1
  opt.mode (1,1) string {mustBeMember(opt.mode,["fr","fr_norm","ratio"])} = "fr"
  opt.avals (1,1) {mustBeLogical} = false
  opt.scale (1,1) {mustBeNumeric,mustBeNonnegative} = 0
  opt.unit (1,1) string {mustBeMember(opt.unit,["s","h"])} = "s"
  opt.ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
end

% validate input
if start >= stop
  error('plotFiringRates:timeInterval','Argument ''start'' must be smaller than ''stop''')
end

% set default values
if opt.avals
  if ~this.hasAvalanches()
    error('plotFiringRates:MissingAvalanches','Avalanches haven''t been computed.')
  end
  % default to same values used for avalanche detection
  window = this.aval_window;
  opt.step = this.aval_step;
  opt.smooth = this.aval_smooth;
  opt.mode = this.aval_method;
end
if opt.scale == 0
  switch opt.mode
    case "fr", opt.scale = 500;
    case "fr_norm", opt.scale = 5;
    case "ratio", opt.scale = 0.5;
  end
end

% x limits
if isempty(start)
  start = this.event_stamps{1}(1);
end
if isempty(stop)
  stop = this.event_stamps{end}(end);
end

% find requested states and regions
[s_indeces,r_indeces,opt.states,opt.regions] = this.indeces(opt.states,opt.regions,rearrange=true);

% make figure if no existing axes is specified
if isempty(opt.ax)
  tit = "Firing rates, " + this.printBasename() + ', w: ' + num2str(window) + ' s, st: ' + num2str(opt.step) + ', sm: ' + num2str(opt.smooth);
  if opt.avals, tit = tit + ', t: ' + num2str(this.aval_threshold); end
  fig = makeFigure('firing_rate',tit);
  opt.ax = gca;
else
  fig = ancestor(opt.ax,'figure');
end

% get traces to plot
[f_rate,time] = this.firingRate('all',opt.regions,window=window,step=opt.step,smooth=opt.smooth,mode=opt.mode);

% filter in [start, stop]
f_rate = Restrict([time,f_rate],[start,stop]);
time = f_rate(:,1); f_rate = f_rate(:,2:end);

% filter by state
state_firing = cell(numel(s_indeces),1);
state_time = cell(numel(s_indeces),1);
for s = 1 : numel(s_indeces)
  s_time = []; s_firing = zeros(0,size(f_rate,2));
  % elements of f_rate inside state
  [~,ind] = Restrict(time,this.state_stamps{s_indeces(s)});
  % points where state changes, to extend state interval and add NaN after
  jump_ind = [false; ind(2:end) ~= ind(1:end-1)+1];
  jump_ind_nan = jump_ind + jump_ind;
  ind_extended = ind([jump_ind(2:end);false]) + 1;
  if ~isempty(ind)
    % assign elements to keep
    new_time_ind = cumsum(jump_ind_nan+1);
    s_time(new_time_ind,1) = time(ind);
    s_firing(new_time_ind,:) = f_rate(ind,:);
  end
  % extend each state interval by one point
  new_ind_extended = find(jump_ind) + 2*(0 : sum(jump_ind)-1).';
  s_time(new_ind_extended,1) = time(ind_extended);
  s_firing(new_ind_extended,:) = f_rate(ind_extended,:);
  % set NaNs between state-changes for plotting
  new_nan_ind = [new_ind_extended+1; numel(s_time)+1];
  s_time(new_nan_ind,1) = NaN;
  s_firing(new_nan_ind,:) = NaN;
  % adjust traces
  s_time = repmat(s_time,size(f_rate,2),1);
  s_firing = s_firing + opt.scale * (0 : size(s_firing,2)-1); % adjust heights
  s_firing = s_firing(:); % flatten for plot
  % adjust unit
  if opt.unit == 'h', s_time = s_time / 3600; end
  % store to plot later
  state_time{s} = s_time;
  state_firing{s} = s_firing;
end

% plot avalanches
if opt.avals
  % get indices again, this time with 'all' if all states are to plot
  [s_ind_aval] = this.indeces(opt.states,opt.regions,fuse=true);
  % set current axes, needed as PlotIntervals doesn't accept axes argument
  axes(opt.ax)
  for s = s_ind_aval
    for r = 1 : numel(opt.regions)
      aval_intervals = this.avalIntervals(this.states(s),opt.regions(r)) - this.aval_window/2;
      valid_ind = aval_intervals(:,1) < stop & aval_intervals(:,2) > start;
      valid_ind = valid_ind | aval_intervals(:,1) < start & aval_intervals(:,2) > stop;
      aval_intervals = aval_intervals(valid_ind,:);
      % adjust unit
      if opt.unit == 'h'
        aval_intervals = aval_intervals / 3600;
      end
      PlotIntervals(aval_intervals,'color',[0.5,0.5,0.5],'alpha',0.15,'ylim',[r-1,r]*opt.scale,'legend','off','bottom',false)
    end
  end
end

% plot firing rates
h = matlab.graphics.chart.primitive.Line.empty;
for s = 1 : numel(s_indeces)
  h(end+1,1) = plot(opt.ax,state_time{s},state_firing{s},Color=myColors(s,'IBMcb'),DisplayName=this.states(s_indeces(s)));
end

% make y labels
y_ticks = opt.scale / 2 * (0 : 2*numel(opt.regions));
labels = regionID2Acr(opt.regions) + '\newlinen: ' + string(this.nNeurons(opt.regions)); % label is region acronym + number of neurons
labels = [repmat("",size(r_indeces.')),labels].';
labels = [labels(:);""];

% adjust plot
if opt.unit == 'h'
  start = start / 3600;
  stop = stop / 3600;
end
adjustAxes(opt.ax,'XLim',[start;stop],'YLim',[0,y_ticks(end)],'YTick',y_ticks,'YTickLabel',labels)
xlabel(opt.ax,"time ("+opt.unit+')');
switch opt.mode
  case "fr", y_label = "population firing rate (Hz)";
  case "fr_norm", y_label = "population firing rate (Hz/neuron)";
  case "ratio", y_label = "population firing ratio (Hz)";
end
ylabel(opt.ax,y_label);
legend(opt.ax)