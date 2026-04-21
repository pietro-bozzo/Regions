function this = computeAvalanches(this,window,smooth,threshold,event_threshold,opt)
% computeAvalanches Compute and store avalanches per region from spiking data
%
% arguments:
%     window             double, time bin (s) for avalanche computation; if zero, average inter-spike interval is used
%     smooth             double = 1, gaussian kernel std in number of samples, default is no smoothing
%     threshold          double = 30, percentile of region firing rate for avalanche computation
%     event_threshold    double = threshold, threshold to use outside sleep events
%
% name-value arguments:
%     step               double = 1, firing rates are computed in windows with overlap 'window' / 'step';
%                        must be integer, default is no overlap
%     perc               logical = true, if true, threshold is a percentile of region firing rate;
%                        otherwise it's absolute
%     mode               string, method used to compute firing rate, either:
%                        'fr'       :  population firing rate, default
%                        'fr_norm'  :  firing rate normalized by number of neurons per region
%                        'ratio'    :  ratio of active units

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  window (1,1) {mustBeNumeric,mustBeNonnegative}
  smooth (1,1) {mustBeNumeric,mustBeGreaterThanOrEqual(smooth,1)} = 1
  threshold (1,1) {mustBeNumeric,mustBeNonnegative} = 30
  event_threshold (1,1) {mustBeNumeric,mustBeNonnegative} = threshold
  opt.step (1,1) {mustBeNumeric,mustBeInteger,mustBePositive} = 1
  opt.perc (1,1) {mustBeLogical} = true
  opt.mode (1,1) string {mustBeMember(opt.mode,["fr","fr_norm","ratio"])} = "fr"
end

if window == 0
  window = this.interSpikeInterval();
else
  [FR,time] = this.firingRate('all','window',window,'step',opt.step,'smooth',smooth,'mode',opt.mode);
end

% detect avalanches on population firing rate
for i = 1 : numel(this.ids)
  if isscalar(window)
    this_fr = FR(:,i);
  else
    [this_fr,time] = this.firingRate('all',this.ids(i),'window',window(i),'step',opt.step,'smooth',smooth,'mode',opt.mode);
  end

  % 1. threshold the firing rate
  if opt.perc
    % case 1: percentile threshold
    profile = percentThreshold(this_fr,threshold);
    if event_threshold ~= threshold
      profile_task = percentThreshold(this_fr,event_threshold);
    end
  else
    % case 2: absolute threshold
    profile = this_fr - threshold;
    profile(profile<0) = 0;
    if event_threshold ~= threshold
      profile_task = this_fr - event_threshold;
      profile_task(profile_task<0) = 0;
    end
  end
  if event_threshold ~= threshold
    % assign task profile to task intervals
    non_sleep_int = vertcat(this.phase.times{~contains(this.phase.names,"sleep")});
    [~,ind] = Restrict(time,non_sleep_int);
    profile(ind) = profile_task(ind);
  end

  % 2. avalanches
  [sizes,intervals,size_t] = avalanchesFromProfile(profile,time(2)-time(1));
  intervals = intervals + time(1); % avalanchesFromProfile assumes time starts at 0 s, add initial offset
  % save results in region object
  this.regions_array(i) = this.regions_array(i).setAvalanches(sizes,intervals,profile,size_t);
end

% store analysis parameters
this.aval_window = window;
this.aval_step = opt.step;
this.aval_smooth = smooth;
this.aval_threshold = threshold;
this.aval_event_threshold = event_threshold;
this.aval_method = opt.mode;
this.aval_t0 = time(1);