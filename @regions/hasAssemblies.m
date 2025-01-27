function value = hasAssemblies(this)
% hasAssemblies Return true iff assemblies have already been computed or set

if isempty(this.asmb_state)
  value = false;
else
  value = true;
end