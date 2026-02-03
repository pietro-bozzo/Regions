function intervals = eventIntervals(this,events)
% eventIntervals Get events' time intervals
%
% repeating arguments:
%     events       (n,1) string, events, default is all recording session's phases; for multiple inputs,
%                  the events of each input are united and results are intersected to get 'intervals'
%
% output:
%     intervals    (m,2) double, event intervals, each row is [start,stop];
%                  intervals are sorted and consolidated (see ConsolidateIntervals)

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments (Input)
  this (1,1) regions
end
arguments (Input, Repeating)
  events (:,1) string
end
arguments (Output)
  intervals (:,2)
end

if isempty(events)

  % default output
  intervals = vertcat(this.phase.times{:});

else

  % 1. union of all events{i}
  int = cell(numel(events),1);
  for i = 1 : numel(events)
    if isempty(events{i})
      % default value
      int{i} = vertcat(this.phase.times{:});
    else
      % check recording session events
      ind = ismember(this.phase.names,events{i});
      int{i} = vertcat(this.phase.times{ind});
      % check states
      ind = ismember(this.state.names,events{i});
      int{i} = [int{i};vertcat(this.state.times{ind})];
      % check other events
      ind = ismember(this.event.names,events{i});
      int{i} = [int{i};vertcat(this.event.times{ind})];
    end
    int{i} = ConsolidateIntervals(sortrows(int{i}));
    if isempty(int{i})
      error('eventIntervals:unknownEvent',"None of the following was found: "+strjoin(events{i},', '))
    end
  end

  % 2. intersection between intervals{:}
  if isscalar(events)
    intervals = int{1};
  else
    intervals = IntersectIntervals(int{1},int{2});
    for i = 3 : numel(events)
      intervals = IntersectIntervals(intervals,int{i});
    end
  end
  
end