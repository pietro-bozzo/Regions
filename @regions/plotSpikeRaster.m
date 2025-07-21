function [fig,h] = plotSpikeRaster(this,start,stop,opt)
% plotSpikeRaster Plot spike raster divided by regions
%
% arguments:
%     start       double = 0, xlim will be [start,stop]
%     stop        double = 0, defaults to max spike time
%
% name-value arguments:
%     states      (n_states,1) string = [], behavioral states, defaults to all states
%     regions     (n_regs,1) double = [], brain regions, defaults to all regions
%     avals       logical = false, if true, plot avalanches
%     colors      spike colors, either double, string or cell, where each row is a state and each column is a region; specify:
%                   - a scalar string, cell, or (1,3) double to have one color for all spikes
%                   - a column vector (or double with three columns) to have one color per state (default),
%                   - a row vector to have one color per region
%     lineProp    cell array of property-value pairs to set raster lines properties (see MATLAB Line Properties)
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
  start (1,1) {mustBeNumeric} = 0
  stop (1,1) {mustBeNumeric,mustBeNonnegative} = 0
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.avals (1,1) {mustBeLogical} = false
  opt.colors = []
  opt.lineProp (:,1) cell = {}
  opt.ax (:,1) matlab.graphics.axis.Axes = matlab.graphics.axis.Axes.empty
  opt.asmb (:,1) double {mustBeInteger,mustBePositive} = [] % DEPRECATED
  opt.ICs (:,1) double {mustBeInteger,mustBePositive} = [] % DEPRECATED
end

% validate input
if stop ~= 0 && start >= stop
  error('plotSpikeRaster:stopValue','Argument ''stop'' must be smaller than ''start''')
end

% find states and regions
[s_indeces,r_indeces,opt.states,opt.regions] = this.indeces(opt.states,opt.regions,rearrange=true);
n_states = numel(opt.states);
n_regions = numel(opt.regions);

% validate colors
make_legend = false; % make legend only if there's one color per state
if isempty(opt.colors)
  colors = repmat(myColors(1:n_states),1,n_regions);
  make_legend = true;
else
  colors = validateColors(opt.colors);
  if size(colors,1) == 1
    colors = repmat(colors,n_states,1);
  elseif size(colors,1) ~= n_states
    error('plotSpikeRaster:colorNumber',"Plotting "+num2str(n_states)+' states but '+num2str(size(colors,1))+' colors were given')
  end
  if size(colors,2) == 1
    colors = repmat(colors,1,n_regions);
    make_legend = true;
  elseif size(colors,2) ~= n_regions
    error('plotSpikeRaster:colorNumber',"Plotting "+num2str(n_regions)+' regions but '+num2str(size(colors,2))+' colors were given')
  end
end

% make figure if no existing axes is specified
if isempty(opt.ax)
  tit = "Raster for " + this.printBasename();
  if opt.avals, tit = tit+', w: '+num2str(this.aval_window)+' s, s: '+num2str(this.aval_smooth)+', t: '+num2str(this.aval_threshold); end
  fig = makeFigure('raster',tit);
  opt.ax = gca;
end

% get spikes to plot
ticks = 0.5;
labels = "";
done_ticks = false;
max_stop = stop;
spikes_cell = cell(n_states,n_regions);
for s = 1 : n_states
  n_units_cum = 0;
  for r = 1 : n_regions
    spikes = this.spikes(opt.states(s),opt.regions(r));
    neurons = this.regions_array(r_indeces(r)).neurons;
    times = spikes(:,1);
    % update left xlim
    if stop <= 0
      stop = -times(end) - 0.001;
      max_stop = max([max_stop,abs(stop)]);
    end
    % keep spikes in requested time
    spikes = spikes(times > start & times < abs(stop),:);
    % relabel units to a contigous {1,...,N} set, preserving unit order
    spikes = compactSpikes(spikes,neurons,clean=true);
    spikes(:,2) = spikes(:,2) + n_units_cum;
    n_units_cum = n_units_cum + numel(neurons);
    spikes_cell{s,r}.spikes = spikes;
    spikes_cell{s,r}.color = colors{s,r};
    if r == 1 && make_legend
      spikes_cell{s,r}.name = this.states(s_indeces(s));
    else
      spikes_cell{s,r}.name = "";
    end
    % make y labels
    if ~done_ticks
      ticks = [ticks;(ticks(end)+n_units_cum+0.5)/2;n_units_cum+0.5];
      labels = [labels;regionID2Acr(opt.regions(r));""];
    end
  end
  done_ticks = true;
end

% plot avalanches
if opt.avals
  % get indices again, this time with 'all' if all states are to plot
  [s_ind_aval] = this.indeces(opt.states,opt.regions,fuse=true);
  % set current axes, needed as PlotIntervals doesn't accept axes argument
  axes(opt.ax)
  for s = s_ind_aval
    height_cum = 0.5;
    for r = r_indeces
      height = this.nNeurons(opt.regions(r));
      aval_intervals = this.avalIntervals(this.states(s),this.ids(r));
      % keep avalanches inside xlim
      valid_ind = aval_intervals(:,1) < max_stop & aval_intervals(:,2) > start;
      valid_ind = valid_ind | aval_intervals(:,1) < start & aval_intervals(:,2) > stop;
      aval_intervals = aval_intervals(valid_ind,:);
      PlotIntervals(aval_intervals,'color',[0.5,0.5,0.5],'alpha',0.15,'ylim',[height_cum,height_cum+height],'legend','off','bottom',false)
      height_cum = height_cum + numel(this.regions_array(r).neurons);
    end
  end
end

% plot spikes
h = cellfun(@(x) RasterPlot(x.spikes,1.111,'Color',x.color,opt.lineProp{:},label=x.name,ax=opt.ax),spikes_cell);
if make_legend
  legend(opt.ax)
end

% adjust plot
if max_stop == start % to prevent error in XLim=[start;max_stop] when no regions have spikes
  max_stop = start + 1;
end
if ticks(end) == 0.5 % to prevent error in YLim=[0.5,ticks(end)] when no regions have spikes
  ticks(end) = 1;
end
adjustAxes(opt.ax,'XLim',[start;max_stop],'YLim',[0.5,ticks(end)],'YTick',ticks,'YTickLabel',labels)
xlabel(opt.ax,'time (s)');
ylabel(opt.ax,'units');

end

function value = validateColors(colors)

  % convert input to cell array
  if isnumeric(colors)
    if mod(size(colors,2),3) ~= 0
      error('validateColors:colorSize','Argument ''colors'' must have triplets of columns')
    end
    colors_cell = cell(size(colors).*[1,1/3]);
    for i = 1 : size(colors,1)
      for j = 1 : size(colors_cell,2)
        colors_cell{i,j} = colors(i,3*(j-1)+(1:3));
      end
    end
    colors = colors_cell;
  elseif ischar(colors)
    colors = cellstr(colors);
  elseif ~iscell(colors) && ~isstring(colors)
    error('validateColors:colorFormat','Argument ''colors'' must be cell, string or numeric')
  end
  try
    value = cellfun(@validatecolor,colors,UniformOutput=false);
  catch ME
    throw(ME)
  end
end

    
    
% % if requested, plot ICs' reactivation strength OLD CODE TO CHECK
% if ~isempty(opt.ICs)
%   yyaxis right
%   for j = j_indeces
%     brain = this.brain_array(j);
%     activity = zscore(brain.ICs_activity);
%     ind = brain.IC_time > start & brain.IC_time < max_stop;
%     plot(opt.ax,brain.IC_time(ind),activity(ind,opt.ICs)*5,Color=myColors(1));
%   end
%   yl = ylim; ylim([0,yl(2)]); ylabel('reactivation strength',FontSize=14); set(gca,YColor='k')
% end


% if an assembly should be highlighted OLD CODE TO HIGHLIGHT an assembly of a region
      % unit_ind = false(size(units));
      % for k = 1 : numel(opt.asmb)
      %   unit_ind = unit_ind | units == opt.asmb(k);
      % end
      % if any(unit_ind) % MOVE TO SEPARATE f called plotHighlightedAsmb
      %   % identify and plot background neurons
      %   other_times = times(~unit_ind);
      %   other_units = units(~unit_ind);
      %   [unique_other_units,~,new_labels] = unique(other_units);
      %   other_units = new_labels + unique_units(1) - 1;
      %   raster([other_times,other_units],'color',[0.5,0.5,0.5]);
      %   % highlight chosen neurons
      %   times = times(unit_ind);
      %   units = units(unit_ind);
      %   [~,~,new_labels] = unique(units);
      %   units = new_labels + unique_units(1) + numel(unique_other_units) - 1;
      % end
      % plot avalanches TO IMPLEMENT
      %if opt.avals
      %  aval_intervals = this.regions_array(j,i).getAvalIntervals(restriction=[start;abs(stop)],threshold=opt.aval_thresh);
      %  plotIntervals(aval_intervals,color=[0.5,0.5,0.5],alpha=0.15,ylim=[unique_units(1),unique_units(end)])
      %end