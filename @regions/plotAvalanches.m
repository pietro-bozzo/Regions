function plotAvalanches(this,opt)
% plotAvalanches Plot spike avalanches over time for each region

arguments
  this (1,1) regions
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = false
end

% find requested states and regions
[j_indeces,i_indeces,opt.states] = this.getIndeces(opt.states,opt.regions);
% plot figures
for i = i_indeces
  fig = figure(Name=string(this.ids(i)),NumberTitle='off',Position=get(0,'Screensize'));
  hold on
  title(append('Avalanches for ',this.basename,', ',regionID2Acr(this.ids(i))), ...
      FontSize=17);
  subtitle(append('n units: ',string(size(this.regions_array(1,i).neurons,1)),', Δt: ', ...
    string(this.regions_array(1,i).spike_dt)),FontSize=14);
  xlabel('t (h)',FontSize=14);
  ylabel('S (# spikes)',FontSize=14);
  set(gca,XLimSpec='Tight',TickDir='out')
  for j = j_indeces
    reg = this.regions_array(j,i);
    plot(reg.getAvalTimes(full=true)/3600,reg.getAvalSizes(full=true));
  end
  legend(opt.states);
  if opt.save
    saveas(fig,append(this.results_path,'/aval_state.',string(this.regions_array(1,i).id),'.svg'), ...
      'svg')
  end
  if ~opt.show
    close(fig)
  end
end