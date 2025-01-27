function this = setAssemblies(this,assemblies,weights,activations)
% setAssemblies Set assembly members of the region object

arguments
  this (1,1) region
  assemblies (:,1) double {mustBeInteger,mustBePositive}
  weights (:,:) double
  activations (:,2) double
end

if numel(assemblies) ~= size(weights,2)
  error('setAssemblies:assembliesSize','Length of assemblies must correspond to second dimension of weights.')
end

if size(weights,1) ~= numel(this.neurons)
  error('setAssemblies:weightSize','First dimension of weights must correspond to number of neurons for this region.')
end

this.assemblies = assemblies;
this.asmb_weights = weights;
this.asmb_activations = activations;