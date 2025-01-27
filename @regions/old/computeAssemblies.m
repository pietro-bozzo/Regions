function this = computeAssemblies(this,opt)
% computeAssemblies Compute assemblies from raw spiking data, divided by regions

arguments
  this (1,1) regions
  opt.time_window (1,1) double = 0
  opt.load (1,1) {mustBeLogical} = true
  opt.save (1,1) {mustBeLogical} = false
end

aggr_asb = [];
sorted_neurons = [];
for i = 1 : size(this.regions_array,2)-1
  this.regions_array(i) = this.regions_array(i).computeAssemblies(time_window=opt.time_window, ...
      load=opt.load,save=opt.save);
  % create matrix for brain assemblies
  aggr_asb = [aggr_asb,zeros(size(aggr_asb,1),size(this.regions_array(i).assemblies,2));zeros(size( ...
    this.regions_array(i).assemblies,1),size(aggr_asb,2)),this.regions_array(i).assemblies];
  sorted_neurons = [sorted_neurons;this.regions_array(i).neurons]; % list to reorder neurons
end
this.regions_array(end) = this.regions_array(end).setNeurons(sorted_neurons);
[~,ind] = sort(sorted_neurons);
this.regions_array(end) = this.regions_array(end).setAssemblies(aggr_asb(:,ind), ...
  this.regions_array(1).time_window);