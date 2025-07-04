function fig = plotSpikeRaster(this,start,stop,opt)
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
%     colors      spike colors, one per state or just one for all spikes
%     lineProp    cell array of property-value pairs to set raster lines properties (see MATLAB Line Properties)
%     ax          Axes = [], axes to plot on, default creates a new figure
%
% output:
%     fig         figure

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
  opt.aval_thresh (1,1) double {mustBeNonnegative} = 0 % DEPRECATED
  opt.asmb (:,1) double {mustBeInteger,mustBePositive} = [] % DEPRECATED
  opt.ICs (:,1) double {mustBeInteger,mustBePositive} = [] % DEPRECATED
end

% validate input
if stop ~= 0 && start >= stop
  error('plotSpikeRaster:stopValue','Argument ''stop'' must be smaller than ''start''')
end

% find requested states and regions
[s_indeces,r_indeces,opt.states,opt.regions] = this.indeces(opt.states,opt.regions,rearrange=true);

% validate colors
if isempty(opt.colors)
  opt.colors = myColors(1:numel(s_indeces));
else
  try
    opt.colors = validatecolor(opt.colors,'multiple');
  catch ME
    throw(ME)
  end
  if size(opt.colors,1) == 1
    opt.colors = repmat(opt.colors,numel(s_indeces),1);
  elseif size(opt.colors,1) ~= numel(s_indeces)
    error('plotSpikeRaster:colorNumber',"Plotting "+num2str(numel(s_indeces))+' states but '+num2str(size(opt.colors,1))+' colors were given')
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
state_spikes = cell(numel(s_indeces),1);
for s = 1 : numel(s_indeces)
  s_spikes = [];
  n_units_cum = 0;
  for r = r_indeces
    spikes = this.spikes(this.states(s_indeces(s)),this.ids(r));
    neurons = this.regions_array(r).neurons;
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
    s_spikes = [s_spikes;spikes];
    % make y labels
    if ~done_ticks
      ticks = [ticks;(ticks(end)+n_units_cum+0.5)/2;n_units_cum+0.5];
      labels = [labels;regionID2Acr(this.ids(r));""];
    end
  end
  done_ticks = true;
  state_spikes{s} = s_spikes;
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
      aval_intervals = this.avalIntervals(this.states(s),this.ids(r)); % ,threshold=opt.aval_thresh
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
for s = 1 : numel(s_indeces)
  raster(state_spikes{s},'Color',opt.colors(s,:),'DisplayName',this.states(s_indeces(s)),opt.lineProp{:},ax=opt.ax)
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
legend(opt.ax)





    
    
% if requested, plot ICs' reactivation strength OLD CODE TO CHECK
if ~isempty(opt.ICs)
  yyaxis right
  for j = j_indeces
    brain = this.brain_array(j);
    activity = zscore(brain.ICs_activity);
    ind = brain.IC_time > start & brain.IC_time < max_stop;
    plot(opt.ax,brain.IC_time(ind),activity(ind,opt.ICs)*5,Color=myColors(1));
  end
  yl = ylim; ylim([0,yl(2)]); ylabel('reactivation strength',FontSize=14); set(gca,YColor='k')
end


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