function [names,time_stamps] = loadEvents(session)
% getEventStamps Load events struct from 'basename.cat.evt' file

arguments
  session (1,:) char
end

[session_path,basename] = fileparts(session);
% load struct using FMAT
events = LoadEvents(append(session_path,'/',basename,'.cat.evt'));
% check that every event has both beginning and end
if rem(numel(events.description),2) ~= 0
  error('loadEvents:FileFormat','Wrong events file format.');
end
% parse struct to unify format
names = string.empty();
time_stamps = {};
tolerance = 1e-8;

skip = false;
for i = 1 : 2 : numel(events.description)
  if ~strcmp(events.description{i}(1:13),'beginning of ') || ~strcmp(events.description{i+1}(1:7),'end of ') || ~strcmp(events.description{i}(14:end),events.description{i+1}(8:end))
    error('loadEvents:FileFormat','Wrong events file format.');
  end
  duration = 0;
  if ~skip
    name = erase(events.description{i}(14:end),basename); % get event name, removing Rat###-########
    name = erase(name,'_');
    name = erase(name,' ');
    if isstrprop(name(1),'digit')
      name = name(2:end);
    end
    if isstrprop(name(end),'digit') && ~strcmp(name(end-5:end-1),'sleep')
      name = name(1:end-1);
    end
    names(end+1,1) = string(name);
    time_stamps{end+1,1} = [events.time(i),events.time(i+1)];
    duration = duration + events.time(i+1) - events.time(i);
    % check for sleep#bis
    if i + 3 < numel(events.description) && strcmp(events.description{i+2},append(events.description{i},'bis'))
      time_stamps{end,1} = [time_stamps{end,1};events.time(i+2),events.time(i+3)];
      duration = duration + events.time(i+3) - events.time(i+2);
      skip = true;
    end
    if duration < tolerance
      warning(append('Duration of event ',name,' is lower than tolerance.'))
    end
  else
    skip = false;
  end
end