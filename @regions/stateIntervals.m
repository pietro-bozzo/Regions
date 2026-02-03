function intervals = stateIntervals(this,states,events,duration)
% stateIntervals Get behavioral state time intervals
%
% arguments:
%     states       (n_states,1) string, behavioral states
%     events       (n_events,1) string, experiment phases
%     duration     double = 0, elapsed time in state to cut intervals at, default is none
%
% output:
%     intervals    (n_intervals,2) double, state intervals, each row is [start,stop] of when the animal was in the state;
%                  intervals are sorted and consolidated (see ConsolidateIntervals)

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  states (:,1) string
  events (:,1) string = []
  duration (1,1) {mustBeNumeric,mustBeNonnegative} = 0
end

% find state
try
  [~,~,s_indeces] = this.arrayInd(states);
catch ME
  throw(ME)
end

% make intervals
intervals = vertcat(this.state.times{s_indeces});
if numel(s_indeces) > 1
  intervals = sortrows(intervals);
  intervals = ConsolidateIntervals(intervals);
end

% restrict to event
if ~isempty(events)
  event_intervals = this.eventIntervals(events);
  intervals = IntersectIntervals(intervals,event_intervals);
end

% restrict total duration
if duration ~= 0
  cum_time = cumsum(diff(intervals,1,2));
  ind = find(cumsum(diff(intervals,1,2))>duration,1);
  if ~isempty(ind)
    intervals = intervals(1:ind,:);
    intervals(end) = intervals(end) - cum_time(ind) + duration;
  end
end