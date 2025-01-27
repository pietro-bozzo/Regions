function activations = asmbActivations(this,state,regs)
% asmbActivations Get activations list of assemblies of requested regions in a state

arguments
  this (1,1) regions
  state (1,1) string = "all"
  regs (:,1) double = []
end

if ~this.hasAssemblies()
  error('asmbActivations:missingICA','Assemblies have not been computed.')
end

% find requested state and regions
[s_index,r_indeces] = this.indeces(state,regs);

% get activations of requested regions
activations = [];
for r = r_indeces
  activations = [activations;this.regions_array(r).asmb_activations];
end

% sort by time
activations = sortrows(activations);

% filter by state
if ~all(all(isnan(activations))) && state ~= "all"
  activations = Restrict(activations,this.state_stamps{s_index},'shift','off');
end