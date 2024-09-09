function plotFiringRates(this,start,time_bin,stop,opt)
% plotFiringRates Plot firing rate of each region TO BE REPLACED BY PLOT ICActivity

arguments
  this (1,1) regions
  start (1,1) double {mustBeNonnegative} = 0
  time_bin (1,1) double {mustBeNonnegative} = 0
  stop (1,1) double {mustBeNonnegative} = 0
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.show_avals (1,1) {mustBeLogical} = false
  opt.threshold (1,1) double {mustBeNonnegative} = 0
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = false
end

% find requested states and regions
[j_indeces,i_indeces,opt.states,opt.regions] = this.getIndeces(opt.states,opt.regions,brain=false);
% plot figure
fig = figure(Name='firing_rates',NumberTitle='off',Position=get(0,'Screensize')); hold on
title(append('Firing rates for ',this.basename,', phase: ',this.phase,', states: [',strjoin( ...
  opt.states,','),'], Δt: ',string(this.brain_array(1).getRateDt)),FontSize=17,FontWeight='Normal');
tiledlayout(numel(i_indeces),1,TileSpacing='Compact');
axs = [];
for i = i_indeces
  axs(i) = nexttile; hold on;
  set(axs(i),TickDir='out')
end
for j = j_indeces
  rates = this.brain_array(j).getFiringRates;
  for i = i_indeces
    plot(axs(i),rates(:,i)); % ADD TIME 
  end
end
if ~opt.show
  close(fig)
end