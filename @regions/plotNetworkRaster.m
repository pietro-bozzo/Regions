function plotNetworkRaster(this,start,stop,opt)
% plotNetworkRaster Plot whole-brain raster and firing rate of each region PROBABLY DEPRECATED

arguments
  this (1,1) regions
  start (1,1) double {mustBeNonnegative}
  stop (1,1) double {mustBeNonnegative}
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.show_avals (1,1) {mustBeLogical} = false
  opt.size_threshold (1,1) double {mustBeNonnegative} = 0
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = false
end

% find requested states and regions
[j_indeces,i_indeces,opt.states,opt.regions] = this.getIndeces(opt.states,opt.regions,brain=false);
% plot figure
fig = figure(Name='raster',NumberTitle='off',Position=get(0,'Screensize')); lines =[]; hold on
title(append('Raster for ',this.basename,', phase: ',this.phase,', states: [',strjoin(opt.states, ...
  ','),'], Δt: ',string(this.brain_array(1).getRateDt)),FontSize=17,FontWeight='Normal');
for j = j_indeces
  rates = this.brain_array(j).getFiringRates(binarize=true).';
  rates = rates(i_indeces,:);
  [regs,times] = find(rates);
  times = times * this.brain_array(j).getRateDt;
  ind = times > start & times < stop;
  line = scatter(times(ind),regs(ind),10,'square','filled');
  lines = [lines;line];
  if opt.show_avals
    aval_intervals = this.brain_array(j).getAvalIntervals(restriction= ...
      [start;stop],threshold=opt.size_threshold);
    plotIntervals(aval_intervals,color=[0.5,0.5,0.5],alpha=0.15)
  end
end
legend(lines,opt.states);
if ~opt.show
  close(fig)
end