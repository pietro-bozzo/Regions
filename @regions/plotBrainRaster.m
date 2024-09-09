function this = plotBrainRaster(this,start,time_bin,stop,opt)
% plotRaster Plot spike raster for whole brain, divided by regions

arguments
  this (1,1) regions
  start (1,1) double {mustBeNonnegative}
  time_bin (1,1) double {mustBeNonnegative}
  stop (1,1) double {mustBeNonnegative}
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.show_avals (1,1) {mustBeLogical} = false
  opt.threshold (1,1) double {mustBeNonnegative} = 0
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = false
end

% find requested states and regions
[j_indeces,i_indeces] = this.getIndeces(opt.states,opt.regions);
% plot figure
fig = figure(Name='raster',NumberTitle='off',Position=get(0,'Screensize')); hold on
title(append('Raster for ',this.basename,', phase: ',this.phase,', states: [', ...
  strjoin(opt.states,','),'], regions: [',strjoin(string(opt.regions),','),'], Δt: ',string( ...
  this.regions_array(1).getSpikeDt)),FontSize=17,FontWeight='Normal');
n_units_cum = 0;
colors = myColors();
ticks = 0;
for i = i_indeces
  if i ~= numel(this.ids)
    n_units = this.regions_array(1,i).getNNeurons;
    for j = j_indeces
      raster = getSpikeRaster(this.regions_array(j,i).getSpikes,start_time=start,bin_size=time_bin, ...
        end_time=stop);
      [units,times] = find(raster);
      units = units + n_units_cum;
      times = times * time_bin + start;
      scatter(times,units,10,colors(mod(i,2)+1+2*(j-1),:),'square','filled')
      if opt.show_avals
        aval_intervals = this.regions_array(j,i).getAvalIntervals(restriction= ...
          [start;stop],threshold=opt.threshold);
        plotIntervals(aval_intervals,color=[0.5,0.5,0.5],alpha=0.15,ylim=[n_units_cum, ...
          n_units_cum+n_units])
      end
    end
    n_units_cum = n_units_cum + n_units;
    ticks = [ticks;n_units_cum];
  end
end
set(gca,TickDir='out',XLim=[start;stop],YLim=[0,n_units_cum],YTick=ticks)
xlabel('time',FontSize=14);
ylabel('units',FontSize=14);
if ~opt.show
  close(fig)
end