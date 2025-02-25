function fig = plotSpikeRaster(this,start,stop,opt)
% plotRaster Plot spike raster divided by regions
%
% arguments:
%     start      double, xlim will be [start,stop]
%     stop       double, default is max spike time
%
% name-value arguments:
%     states     (n_states,1) string = [], behavioral state, default is 'all'
%     regions    (n_regs,1) double = [], brain regions, default is all regions
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
  start (1,1) double {mustBeNonnegative}
  stop (1,1) double {mustBeNonnegative}
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.avals (1,1) {mustBeLogical} = false
  opt.aval_thresh (1,1) double {mustBeNonnegative} = 0
  opt.asmb (:,1) double {mustBeInteger,mustBePositive} = []
  opt.ICs (:,1) double {mustBeInteger,mustBePositive} = []
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = true
end

% find requested states and regions
[s_indeces,r_indeces,opt.states] = this.indeces(opt.states,opt.regions,rearrange=true);

% make figure
fig = figure(Name='raster',NumberTitle='off',Position=get(0,'Screensize')); hold on
title(append('Raster for ',this.printBasename()),FontSize=17,FontWeight='Normal');

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
    if stop <= 0
      stop = -times(end) - 0.001;
      max_stop = max([max_stop,abs(stop)]);
    end
    % keep spikes in requested time
    spikes = spikes(times > start & times < abs(stop),:);
    % relabel units to a contigous {1,...,N} set, preserving unit order
    spikes = compactSpikes(spikes,neurons);
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
  % if 'all' is among states, just plot its avalanches
  s_aval = find(opt.states=='all');
  if isempty(s_aval)
    s_aval = s_indeces;
  end
  for s = s_aval
    height_cum = 0.5;
    for r = r_indeces
      height = numel(this.regions_array(r).neurons);
      aval_intervals = this.avalIntervals(this.states(s_indeces(s)),this.ids(r),restriction=[start,max_stop]); % ,threshold=opt.aval_thresh
      PlotIntervals(aval_intervals,'color',[0.5,0.5,0.5],'alpha',0.15,'ylim',[height_cum,height_cum+height],'legend','off','bottom',false)
      height_cum = height_cum + numel(this.regions_array(r).neurons);
    end
  end
end

% plot spikes
for s = 1 : numel(s_indeces)
  raster(state_spikes{s},'color',myColors(s,'IBMcb'),'DisplayName',this.states(s_indeces(s)))
end

% adjust plot
if max_stop == start % to prevent error in XLim=[start;max_stop] when no regions have spikes
  max_stop = start + 1;
end
if ticks(end) == 0.5 % to prevent error in YLim=[0.5,ticks(end)] when no regions have spikes
  ticks(end) = 1;
end
adjustAxes(gca,'XLim',[start;max_stop],'YLim',[0.5,ticks(end)],'YTick',ticks,'YTickLabel',labels)
xlabel('time (s)',FontSize=14);
ylabel('units',FontSize=14);
legend()

if opt.save
  %saveas(fig,append(this.results_path,'/raster.',string(this.ids(i)),'.svg'),'svg')
end
if ~opt.show
  close(fig)
end





    
    
% if requested, plot ICs' reactivation strength OLD CODE TO CHECK
if ~isempty(opt.ICs)
  yyaxis right
  for j = j_indeces
    brain = this.brain_array(j);
    activity = zscore(brain.ICs_activity);
    ind = brain.IC_time > start & brain.IC_time < max_stop;
    plot(brain.IC_time(ind),activity(ind,opt.ICs)*5,Color=myColors(1));
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