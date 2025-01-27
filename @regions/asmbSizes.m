function [sizes,regs] = asmbSizes(this,regs)
% asmbSizes Get size of assemblies for requested regions

arguments
  this (1,1) regions
  regs (:,1) double = [] % IMPLEMENT POSSIBILITY TO GIVE ACR?
end

if ~this.hasAssemblies()
  error('asmbActivations:missingICA','Assemblies have not been computed.')
end

% find requested regions
[~,r_indeces,~,regs] = this.indeces([],regs);

% get sizes
sizes = {};
for r = r_indeces
  weights = this.regions_array(r).asmb_weights;
  sizes{r,1} = sum(weights~=0,1).';
end