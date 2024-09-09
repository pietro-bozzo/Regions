function plotFRDistr(this,opt)
% plotFRDistr Plot distribution of pooled firing rates of various regions

arguments
  this (1,1) regions
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = false
end

% find requested states and regions
[j_indeces,i_indeces,opt.states,opt.regions] = this.getIndeces(opt.states,opt.regions,brain=false);
% plot figure
fig = figure(Name='fr_distr',NumberTitle='off',Position=get(0,'Screensize')); hold on
title(append('Firing rate disribution for ',this.basename,', phase: ',this.phase,', states: [',strjoin(opt.states, ...
  ','),'], Δt: ',string(this.brain_array(1).getRateDt)),FontSize=17,FontWeight='Normal');
for j = j_indeces
  rates = zscore(this.brain_array(j).getFiringRates()).'; % DEPRECATED
  rates = reshape(rates(i_indeces,:),[],1);
  [counts,edges] = histcounts(rates,Normalization='pdf');
  stairs(edges(1:end-1),counts,LineWidth=0.85)
end
set(gca,Yscale='log',TickDir='out')
legend(opt.states);
if ~opt.show
  close(fig)
end