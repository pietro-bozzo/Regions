function intervals = eventIntervals(this,events,opt)
% eventIntervals Get events' time intervals
%
% repeating arguments:
%     events       (n,1) string, events, default is all recording session's phases; for multiple inputs, the
%                  events of each input are united and results are intersected to get 'intervals' (see examples)
%
% name-value arguments:
%     regexp       logical = false, if true, interpret strings as regular expressions to match event names (see MATLAB regexp)
%     hash         logical = true, if true and if regexp is true, event names are split after last '#', which must be
%                  followed by digits in [1,9] indicating which matching events to consider (see examples)
%     duration     double = 0, elapsed time to cut intervals at, default is none
%
% output:
%     intervals    (m,2) double, event intervals, each row is [start,stop];
%                  intervals are sorted and consolidated (see ConsolidateIntervals)
%
% examples:
%
%     % intersection of 'sleep1' and 'sws' intervals
%     >> eventIntervals("sleep1","sws")
%
%     % union of 'sleep1' and 'sleep2' intervals
%     >> eventIntervals(["sleep1","sleep2"])
%
%     % intersection between 'sleep1' and union of 'rem' and 'sws' intervals
%     >> eventIntervals("sleep1",["rem","sws"])
%
%     % union of all events containing 'sleep' (see MATLAB regexp for a description of regular expressions)
%     >> eventIntervals("sleep",'regexp',true)
%
%     % union of first two events starting with 'task'
%     >> eventIntervals("^task#12",'regexp',true)
%
%     % union of all events containing 'maze' (in case event names already contain '#')
%     >> eventIntervals("maze#",'regexp',true)
%     % or
%     >> eventIntervals("maze",'regexp',true,'hash',false)

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
arguments (Input)
  opt.regexp (1,1) {mustBeLogical} = false
  opt.hash (1,1) {mustBeLogical} = true
  opt.duration (1,1) {mustBeNumeric,mustBeNonnegative} = 0
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

      found = false;
      % check recording session events
      ind = isMatch(this.phase.names,events{i},opt);
      int{i} = vertcat(this.phase.times{ind});
      found = found || any(ind);

      % check states
      ind = isMatch(this.state.names,events{i},opt);
      int{i} = [int{i};vertcat(this.state.times{ind})];
      found = found || any(ind);

      % check other events
      ind = isMatch(this.event.names,events{i},opt);
      int{i} = [int{i};vertcat(this.event.times{ind})];
      found = found || any(ind);

      if ~found
        error('eventIntervals:unknownEvent',"None of the following was found: "+strjoin(events{i},', '))
      end

    end
    int{i} = ConsolidateIntervals(sortrows(int{i}));
    
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

% restrict total duration
if opt.duration ~= 0
  cum_time = cumsum(diff(intervals,1,2));
  ind = find(cumsum(diff(intervals,1,2))>opt.duration,1);
  if ~isempty(ind)
    intervals = intervals(1:ind,:);
    intervals(end) = intervals(end) - cum_time(ind) + opt.duration;
  end
end

end

% --- helper functions ---

function match = isMatch(str,pattern,opt)

if opt.regexp

  match = cell(size(pattern)); % match{i} tells which elements of str match pattern(i)

  for p = 1 : numel(pattern)

    pat = pattern(p);
    keep = true(size(str)); % keep contains elements of matches to consider for pattern(p)

    if opt.hash
      parts = split(pat,"#");
      if numel(parts) > 1
        keep = false(size(str));
        pat = join(parts(1:end-1),''); % restore pattern as everything before last '#'
        for c = char(parts(end))
          % every digit after last '#' indexes a matching element of str to keep
          idx = str2double(c);
          if ~isstrprop(c,'digit') || idx <= 0
            error('eventIntervals:invalidHash','Characters after last ''#'' must be digits in [1,9]')
          elseif idx <= numel(str)
            keep(idx) = true;
          end
        end
      end
    end

    matches = find(cellfun(@(x) ~isempty(x), regexp(str,pat,'forceCellOutput'))); % which elements of str match pattern(p)
    match{p} = Unfind(matches(keep(1:numel(matches))),numel(str));

  end

  % match(i) is true iff str(i) was matched at least by one element of pattern
  match = any([match{:}],2);

else
  match = ismember(str,pattern);
end

end