function info = eventInfo(this,event,restrict,opt)
% eventInfo Get event information matrix
%
% arguments:
%     event       string, event about which to get information
%     restrict    (n,1) string, events to restrict result to
%
% name-value arguments:
%     column      integer, column of info to use for restriction
%
% output:
%     info        (m,l) double, event information, each row corresponds to an event

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  event (1,1) string
  restrict (:,1) string = strings().empty
  opt.column (1,1) {mustBeNumeric,mustBeInteger,mustBePositive} = 1
end

% find event
is_event = this.event.names == event;
if ~any(is_event)
  error('eventInfo:unknownEvent',"Unabelo to find event "+event)
end
info = this.event.values{is_event};
if opt.column > size(info,2)
  error('eventInfo:column',"Argument 'column' cannot be higher than the number of columns of the event information ("+string(size(info,2))+")")
end

% restrict to other events
if ~isempty(restrict)

  restrict_int = getInterval(this,restrict(1));
  for i = 2 : numel(restrict)
    restrict_int = IntersectIntervals(restrict_int,getInterval(this,restrict(i)));
  end

  [~,ind] = Restrict(info(:,opt.column),restrict_int);
  info = info(ind,:);

end

end

% --- helper functions ---

function intervals = getInterval(this,name)

  % check recording session events
  intervals = vertcat(this.phase.times{this.phase.names==name});
  % check states
  intervals = [intervals;vertcat(this.state.times{this.state.names==name})];
  % check other events
  intervals = [intervals;vertcat(this.event.times{this.event.names==name})];
  
  intervals = ConsolidateIntervals(sortrows(intervals));

end