function size_t = avalSizeOverTime(this,state,regs)
% avalProfiles Get avalanche size over time

arguments
  this (1,1) regions
  state (1,1) string
  regs (1,1) string = []
end

if ~this.hasAvalanches()
  error('avalProfiles:MissingAvalanches','Avalanches have not been computed')
end

% find requested state and regions
[~,~,s_index,r_index] = this.arrayInd(state,regs);

intervals = this.regions_array(r_index).aval_intervals;

% get profiles
size_t = this.regions_array(r_index).aval_size_t;


% filter by state
if state ~= "all"
  ind = false(size(intervals(:,1))); % ind(i) = 1 iff interval(i) is in state
  for state_interval = this.state.times{s_index}.'
    ind = ind | intervals(:,1) > state_interval(1) & intervals(:,2) < state_interval(2);
  end
  % keep only avalanche intervals in state
  intervals = intervals(ind,:);
  size_t = size_t(ind);
end

% RESTRICT marche aussi MAIS : il est l'équivalent de intervals(:,1) >= state_interval(1) & intervals(:,2) < state_interval(2);
% au lieu de intervals(:,1) > state_interval(1) & intervals(:,2) < state_interval(2);,
% et il est plus lent

% filter by state
%if state ~= "all"
 % [~,ind1] = Restrict(intervals(:,1), this.state.times{s_index});
  %[~,ind2] = Restrict(intervals(:,2), this.state.times{s_index});
  %ind = intersect(ind1, ind2);
  %intervals = intervals(ind,:);
  %size_t = size_t(ind);
%end