function plotNetworkAval(this,opt)
% plotNetworkAval Plot avalanches computed using ICs of various regions

arguments
  this (1,1) regions
  opt.states (:,1) string = []
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = false
end

% find requested states and regions
[i_indeces,~,opt.states] = this.getIndeces(opt.states);
% plot figure
fig = figure(Name='aval',NumberTitle='off',Position=get(0,'Screensize')); hold on
title(append('Network avalanches for ',this.basename,', window: ',string(this.brain_array(1).IC_window)), ...
  FontSize=17,FontWeight='Normal');
xlabel('t (h)',FontSize=14);
ylabel('S',FontSize=14);
set(gca,TickDir='out')
for i = i_indeces
  brain = this.brain_array(i);
  plot(brain.getAvalTimes(full=true)/3600,brain.getAvalSizes(full=true));
end
legend(opt.states);
if opt.save
  saveas(fig,append(this.results_path,'/network_aval.',string(this.regions_array(1,i).id), ...
    '.svg'),'svg')
end
if ~opt.show
  if ~opt.save
    warning('Both options ''save'' and ''show'' were not selected.')
  end
  close(fig)
end