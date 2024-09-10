function plotAvalDistrByState(this,opt)
% plotAvalDistrByState Plot spike-avalanches size distributions, grouped by state

arguments
  this (1,1) regions
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = false
end

% find requested states and regions
[j_indeces,i_indeces] = this.getIndeces(opt.states,opt.regions);
% plot figures
for j = j_indeces
  fig = figure(Name=this.states(j),NumberTitle='off',Position=get(0,'Screensize')); hold on
  labels = regionID2Acr(this.ids);
  for i = i_indeces
    [counts,edges] = histcounts(this.regions_array(j,i).getAvalSizes(),Normalization='pdf');
    stairs(edges(counts~=0),counts(counts~=0),LineWidth=0.85)
    set(gca,Xscale='log',Yscale='log',TickDir='out')
    labels(i) = append(labels(i),', n: ',string(numel(this.regions_array(1,i).neurons)));
  end
  title(append('Avalanche size distributions for ',this.basename,', state ',this.states(j)) ...
    ,FontSize=17);
  subtitle(append('Δt: ', ...
    string(this.regions_array(1,i).spike_dt)),FontSize=14);
  xlabel('S',FontSize=14);
  ylabel('p(S)',FontSize=14);
  set(gca,TickDir='out')
  legend(labels(i_indeces));
  if opt.save
    print(fig,append(this.results_path,'/size_distr.',string(this.states(j)),'.svg'),'-dsvg')
  end
  if ~opt.show
    close(fig)
  end
end