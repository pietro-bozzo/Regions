function fig = plotUnitFiring(this,start,stop,window,step,opt)
% plotUnitFiring Plot firing rate of each unit per region
%
% arguments:
%     start       double = [], xlim will be [start,stop] in s, default is session beginnnig
%     stop        double = [], default is session end
%     window      double = 0.05, time bin in s
%     step        double = 1, firing rates are computed in windows with overlap 'window' / 'step';
%                 must be integer, default is no overlap
%
% name-value arguments:
%     states      (n_states,1) string = [], behavioral states, defaults to all states
%     regions     (n_regs,1) double = [], brain regions, defaults  all regions
%     smooth      double = 1, gaussian kernel std in number of samples, default is no smoothing
%     clim        (1,2) double = [NaN,NaN]
%     ax          Axes = [], axes to plot on, default creates a new figure
%
% output:
%     fig         figure
%     h           Line handles

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  start {mustBeScalarOrEmpty,mustBeNumeric} = []
  stop {mustBeScalarOrEmpty,mustBeNumeric} = []
  window (1,1) {mustBeNumeric,mustBePositive} = 0.05
  step (1,1) {mustBeNumeric,mustBeInteger,mustBePositive} = 1
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.smooth (1,1) {mustBeNumeric,mustBePositive} = 1
  opt.clim (1,2) double = [NaN,NaN]
  opt.ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
end

% validate input
if start >= stop
  error('plotUnitFiring:stopValue','Argument ''start'' must be smaller than ''stop''')
end

% x limits
if isempty(start)
  start = this.event_stamps{1}(1);
end
if isempty(stop)
  stop = this.event_stamps{end}(end);
end

% find states and regions
[~,~,opt.states,opt.regions] = this.indeces(opt.states,opt.regions,rearrange=true);
n_regions = numel(opt.regions);

% make figure if no existing axes is specified
if isempty(opt.ax)
  tit = "Unit firing, " + this.printBasename() + ', w: ' + num2str(window) + ' s, s: ' + num2str(step);
  fig = makeFigure('unit_fr',tit);
  opt.ax = gca;
end

% firing rate per unit
firing_rates = [];
spikes = this.spikes('all',opt.regions,restrict=[start,stop]);
neurons = this.units(opt.regions);
for n = 1 : numel(neurons)
  f = Frequency(spikes(spikes(:,2)==neurons(n),1),'limits',[start,stop],'binSize',window,'step',step,'smooth',opt.smooth/5);
  firing_rates(n,:) = f(:,2).';
end
time = f(:,1);

% restrict by state, shifting time
state_intervals = this.stateIntervals(opt.states);
state_intervals = state_intervals(any(state_intervals>start,2) & any(state_intervals<stop,2),:);
[time,ind] = Restrict(time,state_intervals,'shift','on');
firing_rates = firing_rates(:,ind);

% plot firing rates
PlotColorMap(firing_rates,'cutoffs',opt.clim,'bar','firing rate (Hz)','x',time,'piecewise','off')

% make y labels
ticks = cumsum([0.5;this.nNeurons(opt.regions)]);
ticks = [ticks.';[(ticks(1:end-1)+ticks(2:end)).'/2,0]];
ticks = ticks(1:end-1);
labels = [regionID2Acr(opt.regions).';strings(1,n_regions)];
labels = ["";labels(:)];

% adjust plot
if ticks(end) == 0.5 % to prevent error in YLim = [0.5,ticks(end)] when no regions have spikes
  ticks(end) = 1;
end
adjustAxes(opt.ax,'XLim',[0,time(end)],'YLim',[0.5,ticks(end)],'YTick',ticks,'YTickLabel',labels)
xlabel(opt.ax,'time (s)');
ylabel(opt.ax,'units');