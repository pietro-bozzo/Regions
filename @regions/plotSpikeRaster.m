function fig = plotSpikeRaster(this,start,stop,opt) % time_bin,
% plotRaster Plot spike raster divided by regions

arguments
  this (1,1) regions
  start (1,1) double {mustBeNonnegative}
  %time_bin (1,1) double {mustBeNonnegative} TO IMPLEMENT
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
[s_indeces,r_indeces,opt.states] = this.indeces(opt.states,opt.regions);

% make figure
fig = figure(Name='raster',NumberTitle='off',Position=get(0,'Screensize')); hold on
title(append('Raster for ',this.printBasename()),FontSize=17,FontWeight='Normal');

% loop over states and regions
ticks = 0.5;
labels = "";
done_ticks = false;
max_stop = stop;
for s = 1 : numel(s_indeces)
  state_spikes = [];
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
    state_spikes = [state_spikes;spikes];
    % plot avalanches TO IMPLEMENT
    % make y labels
    if ~done_ticks
      ticks = [ticks;(ticks(end)+n_units_cum+0.5)/2;n_units_cum+0.5];
      labels = [labels;regionID2Acr(this.ids(r));""];
    end
  end
  done_ticks = true;
  % plot spikes
  raster(state_spikes,'color',myColors(s),'DisplayName',this.states(s_indeces(s)))
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