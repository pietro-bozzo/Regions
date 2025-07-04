function intervals = stateIntervals(this,state)
% stateIntervals Get behavioral state time intervals
%
% arguments:
%     state     string, behavioral state
%
% output:
%     intervals    (n_intervals,2) double, state intervals, each row is [start,stop] of when the animal was in the state

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  state (1,1) string
end

% find state
try
  s_index = this.indeces(state);
catch ME
  throw(ME)
end

intervals = this.state_stamps{s_index};