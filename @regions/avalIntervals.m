function intervals = avalIntervals(this,state,region,opt)
% avalIntervals Get [start,end] intervals of avalanches computed using region spiking data

arguments
  this (1,1) regions
  state (1,1) string
  region (1,1) double
  opt.restriction (:,2) double = []
  opt.threshold (1,1) double {mustBeNonnegative} = 0 % TO IMPLEMENT
end

assert(this.hasAvalanches(),'avalIntervals:MissingAvalanches','Avalanches have not been computed.')

% find requested state and region
[s_index,r_index] = this.indeces(state,region);

% get intervals of requested region
intervals = this.regions_array(r_index).aval_intervals;

% apply restriction
if ~isempty(opt.restriction)
  intervals = intervals(intervals(:,2)>opt.restriction(1) & intervals(:,1)<opt.restriction(2),:);
end

% apply thresholding
%if opt.threshold ~= 0
%  intervals = intervals(this.aval_sizes>opt.threshold,:);
%end

% filter by state
if state ~= "all"
  ind = false(size(intervals(:,1))); % ind(i) = 1 iff interval(i) is in state
  for state_interval = this.state_stamps{s_index}.'
    ind = ind | intervals(:,1) > state_interval(1) & intervals(:,2) < state_interval(2);
  end
  % keep only avalanche intervals in state
  intervals = intervals(ind,:);
end