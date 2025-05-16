function fig = plotAvalRaster(this,start,stop,opt)
% plotRaster Plot avalanche raster divided by regions
%
% arguments:
%     start      double, xlim will be [start,stop]
%     stop       double, defaults to max avalanche time
%
% name-value arguments:
%     states     (n_states,1) string = [], behavioral states, defaults to all states
%     regions    (n_regs,1) double = [], brain regions, defaults to all regions
%     unit       string = 's', unit of time axis, either 's' or 'h'
%
% output:
%     fig        figure

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  start (1,1) {mustBeNumeric} = 0
  stop (1,1) {mustBeNumeric,mustBeNonnegative} = 0
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.unit (1,1) string {mustBeMember(opt.unit,["s","h"])} = "s"
end

% find requested states and regions
[s_indeces,r_indeces,opt.states,opt.regions] = this.indeces(opt.states,opt.regions,rearrange=true);

% make figure
tit = "Avalanche raster for " + this.printBasename() + ', w: ' + num2str(this.aval_window) + ' s, s: ' + num2str(5*this.aval_smooth) + ', t: '+num2str(this.aval_threshold);
fig = makeFigure('aval_raster',tit);

% get avalanches to plot
max_stop = stop;
for s = 1 : numel(s_indeces)
  done_legend = false;
  state = this.states(s_indeces(s));
  for r = 1 : numel(r_indeces)
    intervals = this.avalIntervals(state,this.ids(r_indeces(r)));
    % update left xlim
    if stop <= 0
      stop = -intervals(end,end) - 0.001;
      max_stop = max([max_stop,abs(stop)]);
    end
    % keep intervals in requested time
    ind = intervals >= start & intervals <= abs(stop);
    intervals = intervals(any(ind,2),:);
    % adjust unit
    if opt.unit == 'h'
      intervals = intervals / 3600;
    end
    % plot intervals
    if done_legend
      legend_value = 'off';
    else
      legend_value = this.states(s_indeces(s));
    end
    PlotIntervals(intervals,'color',myColors(s,'IBMcb'),'alpha',1,'ylim',[r-1,r],'legend',legend_value,'bottom','off')
    done_legend = true;
  end
end

% make y labels
y_ticks = 0.5 * (0 : 2*numel(r_indeces));
labels = regionID2Acr(opt.regions) + '\newlinen: ' + string(this.nNeurons(opt.regions)); % label is region acronym + number of neurons
labels = [repmat("",size(r_indeces.')),labels].';
labels = [labels(:);""];

% adjust plot
if max_stop == start % to prevent error in XLim=[start;max_stop] when no regions have spikes
  max_stop = start + 1;
end
adjustAxes(gca,'XLim',[start;max_stop],'YLim',[0,y_ticks(end)],'YTick',y_ticks,'YTickLabel',labels)
xlabel("time ("+opt.unit+')');
ylabel('regions');
PlotIntervals([NaN,NaN],'color',[1,1,1],'legend','no aval','bottom','off')
legend()