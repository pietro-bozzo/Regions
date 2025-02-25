function [state_indeces,region_indeces,found_states,found_regs] = indeces(this,states,regs,opt)
% getIndeces Get indeces of states in state_stamps and of regions in regions_array

arguments
  this (1,1) regions
  states (:,1) string = [] % default gives all states region has been instantiated with
  regs (:,1) double = [] % IMPLEMENT POSSIBILITY TO GIVE ACR?
  opt.strict (1,1) {mustBeLogical} = true
  opt.rearrange (1,1) {mustBeLogical} = false
end

% find requested states
unknown_states = setdiff(states,this.states,'stable');
if ~isempty(unknown_states)
  if opt.strict
    error('indeces:missingState',append('Unrecognized states: ',strjoin(unknown_states,', '),'.'))
  else
    warning('indeces:missingState',append('Unrecognized states: ',strjoin(unknown_states,', '),'.'))
  end
end
if isempty(states)
  state_indeces = 1 : numel(this.states);
  found_states = this.states;
else
  [found_states,~,state_indeces] = intersect(states,this.states,'stable'); % 'stable' preserves input order
  state_indeces = state_indeces.'; % convert to row vector for iterations
end
% move 'all' to first place
if opt.rearrange && ismember('all',found_states)
  found_states = ["all";found_states(found_states~='all')];
  state_indeces = [numel(this.states),state_indeces(state_indeces~=numel(this.states))];
end

% find requested regions
unknown_regions = string(setdiff(regs,this.ids,'stable'));
if ~isempty(unknown_regions)
  if opt.strict
    error('indeces:missingRegion',append('Unrecognized regions: ',strjoin(unknown_regions,', '),'.'))
  else
    warning('indeces:missingRegion',append('Unrecognized regions: ',strjoin(unknown_regions,', '),'.'))
  end
end
if isempty(regs)
  region_indeces = 1 : numel(this.ids);
  found_regs = this.ids;
else
  [found_regs,~,region_indeces] = intersect(regs,this.ids,'stable'); % no 'stable' option to ensure correct plotting I TRYED PUTTING STABLE, LET'S SEE WHAT HAPPENS
  region_indeces = region_indeces.';
end