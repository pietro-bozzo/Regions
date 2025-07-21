function [sizes,intervals] = avalSizes(this,state,region,opt)
% avalSizes Get sizes of avalanches computed using region spiking data
%
% arguments:
%     state          string, behavioral state
%     region         double, brain region
%
% name-value arguments:
%     restriction    (n_restrict,2) double = [], each row is a [start,stop] interval, discard avalanches falling
%                    outside one of these intervals
%     nan_pad        logical = false, if true, add NaN to sizes every time the behavioral state changes
%                    (useful for plotting)
%     threshold      double = 0, discard avalanches with size smaller than threshold
%     d_threshold    double = 0, discard avalanches with duration smaller than d_threshold
%
% output:
%     sizes          (n_avals,1) double, avalanche sizes
%     intervals      (n_avals,2) double, each row is the [start,stop] interval of an avalanche

% NOTE: COULD POOL sizes FOR MANY regions / states IF REQUESTED

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
  opt.d_threshold (1,1) {mustBeNumeric,mustBeNonnegative} = 0
end

if ~this.hasAvalanches()
  error('avalSizes:MissingAvalanches','Avalanches have not been computed.')
end

% find requested state and region
try
  [s_index,r_index] = this.indeces(state,region);
catch ME
  throw(ME)
end

% get intervals and sizes
intervals = this.regions_array(r_index).aval_intervals;
sizes = this.regions_array(r_index).aval_sizes;

% apply restriction
if ~isempty(opt.restriction)
  [~,ind1] = Restrict(intervals(:,1),opt.restriction);
  [~,ind2] = Restrict(intervals(:,2),opt.restriction);
  ind = intersect(ind1,ind2);
  intervals = intervals(ind,:);
  sizes = sizes(ind);
end

% apply thresholding
if opt.threshold ~= 0
  ind = sizes >= opt.threshold;
  intervals = intervals(ind,:);
  sizes = sizes(ind);
end
if opt.d_threshold ~= 0
  ind = diff(intervals,1,2) >= opt.d_threshold;
  intervals = intervals(ind,:);
  sizes = sizes(ind);
end

% filter by state SHOULD DO WITH RESTRICT
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
    intervals = [intervals;intervals(end,:)]; % extend intervals in case last one should be followed by a NaN
    ind(nan_ind) = true;
    sizes(nan_ind,:) = NaN;
  end
  % keep only avalanche intervals and sizes in state
  intervals = intervals(ind,:);
  sizes = sizes(ind);
elseif opt.nan_pad
  intervals = [intervals;intervals(end,:)];
  sizes = [sizes;NaN];
end