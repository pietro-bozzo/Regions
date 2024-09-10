function plotAvalKruskalBar(this,opt)
% plotAvalKruskalBar Plot Kruskal-Wallis test result on spike-avalanches' size, comparing states, divided by 
%                    region

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
fig = figure(Name='kruskal',NumberTitle='off',Position=get(0,'Screensize')); hold on
states_title = "states: ["; % prepare text for plot title
title_ready = false;
for i = i_indeces
  subplot(2,ceil(numel(i_indeces)/2),i); hold on
  sizes = [];
  groups = [];
  for j = j_indeces
    s = this.regions_array(j,i).getAvalSizes();
    sizes = [sizes;s];
    groups = [groups;repmat(j,size(s))];
    if ~title_ready
      states_title = append(states_title,string(this.states(j)),', ');
    end
  end
  title_ready = true;
  kruskalbar(sizes,groups,0.05,true);
  title(append(regionID2Acr(this.ids(i))),FontSize=14);
  subtitle(append('n units: ',string(size(this.regions_array(1,i).neurons,1))),FontSize=14);
  ylabel('S',FontSize=14);
  %legend(opt.states);
end
sgtitle(append('Avalanche size distributions comparison for ',this.basename,', ',extractBefore( ...
  states_title,strlength(states_title)-1),'], Δt: ', ...
  string(this.regions_array(1,1).spike_dt))); % removing last comma from states_title
if opt.save
  saveas(fig,append(this.results_path,'/size_comp','.svg'),'svg')
end
if ~opt.show
    close(fig)
end