function this = computeAvalanches(this,window,smooth,threshold,event_threshold)
% computeAvalanches Compute and store avalanches per region from spiking data
%
% arguments:
%     window             double = 0.01, time bin (s) for avalanche computation
%     smooth             double = 2, gaussian kernel std in number of samples
%     threshold          double = 30, percentile of region firing rate for avalanche computation
%     event_threshold    double = 0, threshold to use outside sleep events, defaults to threshold + 10

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  window (1,1) double {mustBePositive} = 0.01 % i.e., 10 ms
  smooth (1,1) double {mustBeNonnegative} = 2
  threshold (1,1) double {mustBeNonnegative} = 30
  event_threshold (1,1) double {mustBeNonnegative} = 0
end

% set default value
if event_threshold == 0, event_threshold = min(threshold+10,100); end

% detect avalanches on population firing rate
for i = 1 : numel(this.ids)
  [FR,time] = this.firingRate('all',this.ids(i),window=window,smooth=smooth);
  % threshold firing rate
  profile = percentThreshold(FR,threshold);
  % threshold differently for non sleep events
  if event_threshold ~= threshold
    profile_task = percentThreshold(FR,event_threshold);
    % assign task profile to task intervals
    ind = false(size(time));
    for interval = vertcat(this.phase_stamps{~contains(this.phases,"sleep")}).'
      ind = ind | (time >= interval(1) & time <= interval(2));
    end
    profile(ind) = profile_task(ind);
  end
  % get avalanches
  [sizes,intervals] = avalanchesFromProfile(profile,window);
  intervals = intervals + time(1); % avalanchesFromProfile assumes time starts at 0 s, add initial offset
  % save results in region object
  this.regions_array(i) = this.regions_array(i).setAvalanches(sizes,intervals,profile);
end

% store analysis parameters
this.aval_window = window;
this.aval_smooth = smooth;
this.aval_threshold = threshold;
this.aval_event_threshold = event_threshold;
this.aval_t0 = time(1);