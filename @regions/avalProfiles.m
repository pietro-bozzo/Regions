function [profiles,time] = avalProfiles(this,state,regs)
% avalProfiles Get activity profiles used to compute avalanches
%
% arguments:
%     state       string, behavioral state
%     region      (n,1) string, brain region
%
% output:
%     profiles    (m,n) double, activity profiles over time, zeros separate avalanches
%     time        (m,1) double, time stamps for profiles

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  state (1,1) string
  regs (:,1) string = []
end

if ~this.hasAvalanches()
  error('avalProfiles:MissingAvalanches','Avalanches have not been computed')
end

% find state and regions
[~,~,s_index,r_indeces] = this.arrayInd(state,regs);

% get profiles
profiles = [];
for r = r_indeces
  profiles = inhomogeneousHorzcat(profiles,this.regions_array(r).aval_profile);
end
time = (this.aval_t0 : this.aval_window : this.aval_t0 + this.aval_window * (size(profiles,1)-1)).';

% filter by state
if state ~= "all"
  ind = false(size(time(:,1))); % ind(i) = 1 iff time(i) is in state
  for state_interval = this.state.times{s_index}.'
    ind = ind | time >= state_interval(1) & time <= state_interval(2);
  end
  time = time(ind);
  profiles = profiles(ind);
end