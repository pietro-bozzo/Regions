function intervals = stateIntervals(this,states)
% stateIntervals Get behavioral state time intervals
%
% arguments:
%     states       (n_states,1) string, behavioral states
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
end

% find state
try
  s_indeces = this.indeces(states);
catch ME
  throw(ME)
end

intervals = vertcat(this.state_stamps{s_indeces});

if numel(s_indeces) > 1
  intervals = sortrows(intervals);
  intervals = ConsolidateIntervals(intervals);
end