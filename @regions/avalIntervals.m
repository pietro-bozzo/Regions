function intervals = avalIntervals(this,state,region,opt)
% avalIntervals Get [start,stop] intervals of avalanches computed using region spiking data
%
% arguments:
%     state          string, behavioral state
%     region         double, brain region
%
% name-value arguments:
%     restriction    (n_restrict,2) double = [], each row is a [start,stop] interval, discard avalanches falling
%                    outside one of these intervals
%     nan_pad        logical = false, if true, add [NaN,NaN] in between intervals every time the behavioral state changes
%                    (useful for plotting)
%     threshold      double = 0, discard avalanches with duration smaller than threshold
%
% output:
%     intervals      (n_avals,2) double, each row is the [start,stop] interval of an avalanche

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  state (1,1) string
  region (1,1) {mustBeNumeric,mustBeInteger}
  opt.restriction (:,2) {mustBeNumeric} = []
  opt.nan_pad (1,1) {mustBeLogical} = false
  opt.threshold (1,1) {mustBeNumeric,mustBeNonnegative} = 0
end

if ~this.hasAvalanches()
  error('avalIntervals:MissingAvalanches','Avalanches have not been computed')
end

% find requested state and region
[s_index,r_index] = this.indeces(state,region);

% get intervals of requested region
intervals = this.regions_array(r_index).aval_intervals;

% apply restriction
if ~isempty(opt.restriction)
  [~,ind1] = Restrict(intervals(:,1),opt.restriction);
  [~,ind2] = Restrict(intervals(:,2),opt.restriction);
  intervals = intervals(intersect(ind1,ind2),:);
end

% apply thresholding
if opt.threshold ~= 0
  ind = intervals(:,2)-intervals(:,1) >= opt.threshold;
  intervals = intervals(ind,:);
end

% filter by state
if state ~= "all"
  ind = false(size(intervals(:,1))); % ind(i) = 1 iff interval(i) is in state
  nan_ind = [];
  for state_interval = this.state_stamps{s_index}.'
    new_ind = intervals(:,1) > state_interval(1) & intervals(:,2) < state_interval(2);
    if any(new_ind)
      ind = ind | new_ind;
      nan_ind(end+1) = find(new_ind,1,'last') + 1; % nan_ind(j) is i : at time(i) state ends
    end
  end
  if opt.nan_pad % add NaNs at the end of each state interval to allow plotting
    ind(nan_ind) = true;
    intervals(nan_ind,:) = NaN;
  end
  % keep only avalanche intervals in state
  intervals = intervals(ind,:);
elseif opt.nan_pad
  intervals = [intervals;nan(1,size(intervals,2))];
end