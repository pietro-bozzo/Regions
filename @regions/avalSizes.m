function [sizes,intervals] = avalSizes(this,state,region,opt)
% avalSizes Get sizes of avalanches computed using region spiking data
%
% arguments:
%     state          string, behavioral state
%     region         double, brain region
%
% name-value arguments:
%     restriction    (n_restrict,2) double = [], each row is a [start,stop] interval, avalanches not falling
%                    in one of these intervals will be discarded
%     nan_pad        logical = false, if true, add NaN to sizes every time the behavioral state changes
%                    (useful for plotting)
%     threshold      double = 0, NOT IMPLEMENTED
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
  region (1,1) double
  opt.restriction (:,2) double = []
  opt.nan_pad (1,1) {mustBeLogical} = false
  opt.threshold (1,1) double {mustBeNonnegative} = 0 % TO IMPLEMENT
end

if ~this.hasAvalanches()
  error('avalSizes:MissingAvalanches','Avalanches have not been computed.')
end

% find requested state and region
[s_index,r_index] = this.indeces(state,region);

% get intervals and sizes
intervals = this.regions_array(r_index).aval_intervals;
sizes = this.regions_array(r_index).aval_sizes;

% apply restriction
if ~isempty(opt.restriction)
  ind = intervals(:,1) > opt.restriction(1) & intervals(:,2) < opt.restriction(2);
  intervals = intervals(ind,:);
  sizes = sizes(ind);
end

% apply thresholding
%if opt.threshold ~= 0
%  intervals = intervals(this.aval_sizes>opt.threshold,:);
%end

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
    sizes(nan_ind,:) = NaN;
  end
  % keep only avalanche intervals and sizes in state
  intervals = intervals(ind,:);
  sizes = sizes(ind);
elseif opt.nan_pad
  intervals = [intervals;intervals(end,:)];
  sizes = [sizes;NaN];
end