function [profiles,time] = avalProfiles(this,state,regs)
% avalProfiles Get activity profiles used to compute avalanches

arguments
  this (1,1) regions
  state (1,1) string % NOT IMPLEMENTED
  regs (:,1) double {mustBeInteger} = []
end

if ~this.hasAvalanches()
  error('avalProfiles:MissingAvalanches','Avalanches have not been computed.')
end

% find requested state and regions
[s_index,r_indeces] = this.indeces(state,regs);

% get profiles
profiles = [];
for r = r_indeces
  profiles = inhomogeneousHorzcat(profiles,this.regions_array(r).aval_profile);
end

% if requested, output time for profiles
if nargout > 1
  time = (this.aval_t0 : this.aval_window : this.aval_t0 + this.aval_window * (size(profiles,1)-1)).';
end

% filter by state NOT IMPLEMENTED
%if state ~= "all"
%  ind = false(size(intervals(:,1))); % ind(i) = 1 iff interval(i) is in state
%  for state_interval = this.state_stamps{s_index}.'
%    ind = ind | intervals(:,1) > state_interval(1) & intervals(:,2) < state_interval(2);
%  end
%  % keep only avalanche intervals in state
%  intervals = intervals(ind,:);
%end