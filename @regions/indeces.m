function [state_indeces,region_indeces,found_states,found_regs] = indeces(this,states,regs,opt)
% getIndeces Get indeces of states in state_stamps and of regions in regions_array

arguments
  this (1,1) regions
  states (:,1) string = [] % default gives all states region has been instantiated with
  regs (:,1) double = [] % IMPLEMENT POSSIBILITY TO GIVE ACR?
  opt.strict (1,1) {mustBeLogical} = true
  opt.rearrange (1,1) {mustBeLogical} = false
  opt.fuse (1,1) {mustBeLogical} = false % if true, return 'all' when no states resquested
end

% validate input
unknown_states = setdiff(states,this.states,'stable');
if ~isempty(unknown_states)
  if opt.strict
    error('indeces:missingState',"Unrecognized states: " + strjoin(unknown_states,', '))
  else
    warning('indeces:missingState',"Unrecognized states: " + strjoin(unknown_states,', '))
  end
end
unknown_regions = string(setdiff(regs,this.ids,'stable'));
if ~isempty(unknown_regions)
  if opt.strict
    error('indeces:missingRegion',"Unrecognized regions: " + strjoin(unknown_regions,', '))
  else
    warning('indeces:missingRegion',"Unrecognized regions: " + strjoin(unknown_regions,', '))
  end
end

% 1. find requested states
if isempty(states)
  % case 1: no states requested
  if numel(this.states) == 2
    % if 'all' is the only state, return it
    state_indeces = find(this.states == "all");
  else
    % otherwise return all states and 'other'
    state_indeces = find(this.states~='all').';
  end
  found_states = this.states(state_indeces);
else
  % case 2: identify requested states
  [found_states,~,state_indeces] = intersect(states,this.states,'stable'); % 'stable' preserves input order
  state_indeces = state_indeces.'; % convert to row vector for iterations
end
% if 'all' option is requested or if it's the only state, return it
if opt.fuse && numel(state_indeces) == numel(this.states)-1
  found_states = "all";
  state_indeces = find(this.states=="all");
end

% move 'all' to first place DEPRECATED??
if opt.rearrange && ismember('all',found_states)
  found_states = ["all";found_states(found_states~='all')];
  state_indeces = [numel(this.states)-1,state_indeces(state_indeces~=numel(this.states)-1)];
end

% 2. find requested regions
if isempty(regs)
  % case 1: no regions requested
  region_indeces = 1 : numel(this.ids);
  found_regs = this.ids;
else
  % case 2: identify requested regions
  [found_regs,~,region_indeces] = intersect(regs,this.ids,'stable'); % no 'stable' option to ensure correct plotting I TRYED PUTTING STABLE, LET'S SEE WHAT HAPPENS
  region_indeces = region_indeces.';
end