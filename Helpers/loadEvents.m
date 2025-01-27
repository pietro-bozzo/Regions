function [names,times] = loadEvents(session)
% getEventStamps Load events struct from 'basename.cat.evt' file

arguments
  session (1,:) char
end

% read file
[session_path,basename] = fileparts(session);
fileID = fopen(append(session_path,'/',basename,'.cat.evt'));

names = string.empty();
times = {};
duplicate = false;
line = 'a'; % initialize to char
i = 0;
while ischar(line)
  % read line
  line = fgetl(fileID);
  if ischar(line)
    line = replace(line,char(9),' '); % char(9) is tab
    words = strsplit(line,' ');

    % check line format
    if numel(words) ~= 4 || words{3} ~= "of"
      error('loadEvents:fileFormat','Wrong events file formnat.')
    end

    % prepare event name
    name_parts = strsplit(words{4},'_');
    if all(isstrprop(name_parts{end},'digit'))
      name_parts = name_parts(1:end-1); % remove last number
    end
    if name_parts{end}(end-2:end) == "bis"
      name_parts{end} = name_parts{end}(1:end-3); % remove 'bis' to correctly detect duplicates
    end

    if rem(i,2) == 0
      % check line format
      if words{2} ~= "beginning"
        error('loadEvents:fileFormat','Wrong events file formnat.')
      end

      % if an event is repeating
      if ~isempty(names) && name_parts{end} == names(end)
        duplicate = true; % flag repetition
        times{end}(end+1,1) = str2num(words{1}) / 1000; % save time stamps next to previous event, converted to seconds
      else
        % save new event
        names = [names;name_parts{end}];
        times{end+1,1} = str2num(words{1}) / 1000;
      end
    else
      % check line format
      if words{2} ~= "end"
        error('loadEvents:fileFormat','Wrong events file formnat.')
      end
      if name_parts{end} ~= names(end)
        error('loadEvents:fileFormat',append('Unable to find two time stamps for event ',names(end),'.'))
      end
      if duplicate
        times{end}(end,2) = str2num(words{1}) / 1000;
        duplicate = false;
      else
        times{end}(end,2) = str2num(words{1}) / 1000;
      end
    end
    i = i + 1;
  end
end

fclose(fileID);

% if LoadEvents errors when reading Rat###-########.cat.evt, there might be a BOM byte at the beginning of the fil, to remove on bash with: 
% $ sed -i 's/\xef\xbb\xbf//' Rat003_20231217.cat.evt   