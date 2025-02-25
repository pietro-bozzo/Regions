function [list,regs] = asmbAnatomy(this,regs)
% asmbAnatomy Get list of assemblies for requested regions

arguments
  this (1,1) regions
  regs (:,1) double = []
end

assert(this.hasAssemblies(),'asmbAnatomy:MissingAssemblies','Assemblies have not been computed.')

% find requested regions
[~,r_indeces,~,regs] = this.indeces([],regs);

list = [];
for r = r_indeces
  assemblies = this.regions_array(r).assemblies;
  if isempty(assemblies)
    list = [list;NaN,NaN];
  else
    list = [list;assemblies(1),assemblies(end)];
  end
end