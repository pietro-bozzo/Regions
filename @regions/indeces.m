function [state_indeces,region_indeces,found_states,found_regs] = indeces(this,states,regs,opt)
% getIndeces Get indeces of states in state_stamps and of regions in regions_array

arguments
  this (1,1) regions
  states (:,1) string = [] % default gives all states region has been instantiated with
  regs (:,1) double = [] % IMPLEMENT POSSIBILITY TO GIVE ACR?
  opt.brain (1,1) {mustBeLogical} = true
  opt.strict (1,1) {mustBeLogical} = true
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
% OLD
% if isempty(states)
%   state_indeces = 1 : numel(this.states);
%   found_states = this.states;
% else
%   state_indeces = [];
%   found_states = [];
%   for state = states.'
%     index = find(this.states==state);
%     if isempty(index)
%       if opt.strict
%         error('indeces:missingState',append('Unrecognized state: ',state))
%       else
%         warning('indeces:missingState',append('Unrecognized state: ',state))
%       end
%     else
%       state_indeces = [state_indeces,index];
%       found_states = [found_states;state];
%     end
%   end
% end

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
  [found_regs,~,region_indeces] = intersect(regs,this.ids); % no 'stable' option to ensure correct plotting
  region_indeces = region_indeces.';
end
% if ~opt.brain && any(regs==0)
%   warning('Region 0 was requested but excluded.') % CHANGE: REGION 0 WILL BE REPLACED BY BRAIN (MAYBE)
% end
% if isempty(regs)
%   region_indeces = 1 : numel(this.ids);
%   found_regs = this.ids;
% else
%   region_indeces = [];
%   found_regs = [];
%   for reg = regs.'
%     index = find(this.ids==reg);
%     if isempty(index)
%       if opt.strict
%         error('indeces:missingRegion',append('Unrecognized region: ',string(reg)))
%       else
%         warning('indeces:missingRegion',append('Unrecognized region: ',string(reg)))
%       end
%     else
%       region_indeces = [region_indeces,index];
%       found_regs = [found_regs;reg];
%     end
%   end
% end
% if ~opt.brain
%   region_indeces = region_indeces(regs~=0);
%   regs = regs(regs~=0);
% end