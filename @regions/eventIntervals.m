function intervals = eventIntervals(this,events)
% stateIntervals Get behavioral state time intervals
%
% arguments:
%     events       (n_events,1) string, session events, default is whole session
%
% output:
%     intervals    (n_intervals,2) double, state intervals, each row is [start,stop] of session events;
%                  intervals are sorted and consolidated (see ConsolidateIntervals) NOT AT THE MOMENT

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  events (:,1) string = []
end

if isempty(events)
  ind = 1 : numel(this.event_stamps);
else
  unknown_events = setdiff(events,this.event_names);
  if ~isempty(unknown_events)
    error('eventIntervals:unknownEvent',"Unrecognized events: "+strjoin(unknown_events,', '))
  end
  ind = ismember(this.event_names,events);
end

intervals = vertcat(this.event_stamps{ind});

% if numel(ind) > 1 % not necessary thanks to event_stamps format
%   intervals = sortrows(intervals);
%   intervals = ConsolidateIntervals(intervals);
% end