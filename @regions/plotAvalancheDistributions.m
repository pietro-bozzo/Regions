function plotAvalancheDistributions(this,opt)
% plotAvalancheDistributions Plot spike-avalanches size distributions, divided by regions

arguments
  this (1,1) regions
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = false
end

% find requested states and regions
[j_indeces,i_indeces,opt.states,opt.regions] = this.getIndeces(opt.states,opt.regions);
% plot figures
for i = i_indeces
  fig = figure(Name=string(this.ids(i)),NumberTitle='off',Position=get(0,'Screensize'));
  hold on
  for j = j_indeces
    [counts,edges] = histcounts(this.regions_array(j,i).getAvalSizes(),Normalization='pdf');
    stairs(edges(counts~=0),counts(counts~=0),LineWidth=0.85)
    set(gca,Xscale='log',Yscale='log',TickDir='out')
  end
  title(append('Avalanche size distributions for ',this.basename,', ',regionID2Acr( ...
    this.ids(i))),FontSize=17);
  subtitle(append('n units: ',string(size(this.regions_array(1,i).neurons,1)),', Δt: ', ...
    string(this.regions_array(1,i).spike_dt)),FontSize=14);
  xlabel('S',FontSize=14);
  ylabel('p(S)',FontSize=14);
  set(gca,TickDir='out')
  legend(opt.states);
  if opt.save
    saveas(fig,append(this.results_path,'/size_distr.',string(this.ids(i)),'.svg'),'svg')
  end
  if ~opt.show
    close(fig)
  end
end