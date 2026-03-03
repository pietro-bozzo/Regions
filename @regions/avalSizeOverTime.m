function [size_t,time] = avalSizeOverTime(this,state,reg)
% avalSizeOverTime Get avalanche size over time
%
% arguments:
%     state     string, behavioral state
%     region    string, brain region
%
% output:
%     size_t    (n,1) double, avalanche size over time, each 0 represents the beginning of an avalanche
%     time      (n,1) double, time stamps for size_t

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  state (1,1) string
  reg (1,1) string = []
end

if ~this.hasAvalanches()
  error('avalSizeOverTime:MissingAvalanches','Avalanches have not been computed')
end

% find state and region
[~,~,s_index,r_index] = this.arrayInd(state,reg);

% get profile
size_t = this.regions_array(r_index).aval_size_t;
if size_t(1) ~= 0
  size_t = [0;size_t];
end
intervals = this.regions_array(r_index).aval_intervals;

% filter by state
if state ~= "all"
  % find avalanches inside state
  ind = false(size(intervals(:,1))); % ind(i) = 1 iff interval(i) is in state
  for state_interval = this.state.times{s_index}.'
    ind = ind | intervals(:,1) >= state_interval(1) & intervals(:,2) <= state_interval(2);
  end
  intervals = intervals(ind,:);
  % separate avalanches in size_t
  aval_idx = find(~size_t);
  aval_idx = [aval_idx,[aval_idx(2:end)-1;numel(size_t)]]; % aval_idx(i,:) is [start, stop] indeces of i-th avalanche
  % keep only avalanches inside state
  aval_idx = aval_idx(ind,:);
  keep_idx = linspaceVector(aval_idx(:,1),aval_idx(:,2));
  size_t = size_t(keep_idx);
end

if nargout > 1
  time = linspaceVector(intervals(:,1),intervals(:,2),this.aval_window);
end