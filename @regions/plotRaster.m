function this = plotRaster(this,start,time_bin,stop,opt)
% plotRaster Plot spike raster and firing rate for whole brain, divided by regions

arguments
  this (1,1) regions
  start (1,1) double {mustBeNonnegative}
  time_bin (1,1) double {mustBeNonnegative}
  stop (1,1) double {mustBeNonnegative}
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.region_bin (1,1) double {mustBePositive} = 1
  opt.scatter (1,1) {mustBeLogical} = false
  opt.show_avals (1,1) {mustBeLogical} = false
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = false
end

% find requested states and regions
[j_indeces,i_indeces,opt.states] = this.getIndeces(opt.states,opt.regions);
% plot figures
for i = i_indeces
  fig = figure(Name=string(this.ids(i)),NumberTitle='off',Position=get(0,'Screensize'));
  t = tiledlayout(3,1,TileSpacing='Compact'); raster_ax = nexttile(1,[2,1]); hold on; rate_ax = nexttile;
  hold on; axes(raster_ax); img = 0; lines = [];
  for j = j_indeces
    neurons = this.regions_array(j,i).neurons;
    spikes = reorderSpikes(this.regions_array(j,i).getSpikes,neurons);
    if opt.scatter
      raster = getSpikeRaster(spikes,start_time=start,bin_size=time_bin,end_time=stop);
      [units,times] = find(raster);
      times = times * time_bin + start;
      scatter(times,units,40,'square','filled')
      if opt.show_avals
        aval_intervals = this.regions_array(j,i).getAvalIntervals(restriction= ...
          [start;stop]); % REMOVE INTERVALS SMALLER THAN THRESHOLD?
        PlotIntervals(aval_intervals,'color',[0.5,0.5,0.5],'alpha',0.15)
      end
    else
      img = img + histcounts2(spikes(:,2),spikes(:,1), ...
        0 : opt.region_bin : numel(neurons), ...
        start : time_bin : stop+time_bin);
    end
    [firing_rate,times] = this.regions_array(j,i).getFiringRate(time_bin, ...
      restriction=[start;stop]);
    line = stairs(rate_ax,times(1:end-1),firing_rate);
    lines = [lines;line];
  end
  if ~opt.scatter
    imagesc([start,stop],[0,numel(neurons)],img);
  end
  set(raster_ax,TickDir='out',XLim=[start;stop],XTick=[],YLim=[0,numel(neurons)])
  set(rate_ax,TickDir='out',XLim=[start;stop])
  title(t,append('Raster for ',this.basename,', ',regionID2Acr(this.ids(i))),FontSize=17);
  subtitle(append('n units: ',string(size(this.regions_array(1,i).neurons,1)),', Δt: ', ...
    string(this.regions_array(1,i).spike_dt)),FontSize=14);
  xlabel(rate_ax,'time',FontSize=14); ylabel(rate_ax,'rate',FontSize=14);
  ylabel(raster_ax,'units',FontSize=14);
  legend(rate_ax,lines,opt.states);
  if opt.save
    saveas(fig,append(this.results_path,'/raster.',string(this.ids(i)),'.svg'),'svg')
  end
  if ~opt.show
    if ~opt.save
      warning('Both options ''save'' and ''show'' were not selected.')
    end
    close(fig)
  end
end