classdef regions
% regions Handler for multi-region spiking data, to store data and compute quantities per region (e.g., firing rates, avalanches, assemblies)
%     requires FMAToolbox, ISAC, region
%
% properties:
%
% methods:
%

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

properties (GetAccess = public, SetAccess = protected)
  % data
  basename        % session basename, e.g., Rat386-20180918
  session_path    % path to Pietro folder in this session
  rat
  event_names
  event_stamps
  all_events
  states
  state_stamps
  ids
  regions_array
  % avalanches parameters
  aval_window
  aval_smooth
  aval_threshold
  aval_event_threshold
  aval_method
  aval_t0
  % assemblies parameters
  asmb_method
  asmb_state
  asmb_event
  asmb_window
end
  
  methods
    function obj = regions(session,opt)
      % regions Construct an instance of this class
      %
      % arguments:
      % session (1,:) char
      % results_path (1,1) string = ""
      % phases (1,1) string = "all"    either a cell of n x 2 matrices of time stamps or names of protocol phases
      % states (:,1) string = "all"    states to load, default aggregates  all data in a single state named "all"
      % regions (:,1) double {mustBeInteger,mustBeNonnegative} = []    regions to load, default loads all regions of data
      % load_spikes (1,1) {mustBeLogical} = false    if false, do not load spikes, to access just states and events

      arguments
        session (1,:) char
        opt.results_path (1,1) string = "" % NOT IMPLEMENTED
        opt.events (:,1) string = "all"
        opt.states (:,1) string = "all"
        opt.regions (:,1) {mustBeNumeric,mustBeInteger,mustBeNonnegative} = []
        opt.load_spikes (1,1) {mustBeLogical} = true
        opt.verbose (1,1) {mustBeLogical} = true
      end

      % assign members
      [session_path,basename] = fileparts(session);
      obj.basename = basename;
      obj.session_path = append(session_path,'/Pietro');
      obj.rat = str2double(obj.basename(4:6));

      % validate format of option phase REMOVE, SHOULD JUST BE NAMES OF EVENTS
      % if iscell(opt.events)
      %   for phase = opt.events.'
      %     if ~isnumeric(phase{1})
      %       error('mustBeNumericOrString:WrongType','Invalid value for ''phases'' argument. Value must be a cell array of numerics or a string array.')
      %     else
      %       if ~ismatrix(phase{1}) || size(phase{1},2) ~= 2
      %         error('mustHaveDims:WrongDim','Invalid value for ''phases'' argument. Value must be a cell array of matrices with two columns.')
      %       elseif any(any(phase{1}<0))
      %         error('mustBeNonnegative:Negative','Invalid value for ''phases'' argument. Value must be non negative')
      %       end
      %     end
      %   end
      %   obj.phase_stamps = opt.events; % keep user defined phase stamps
      % else
      %   if isnumeric(opt.events)
      %     error('mustBeNumericOrString:WrongType','Invalid value for ''phase'' argument. Value must be a cell array of numerics or a string array.')
      %   end
      %  try
      %    opt.events = string(opt.events);
      %  catch
      %    error('mustBeNumericOrString:WrongType','Invalid value for ''phase'' argument. Value must be a cell array of numerics or a string array.')
      %  end
      % end

      % load protocol-events time stamps COULD ADD try catch AND HANDLE MISSING .cat.evt FILE AS I DID BEFORE
      [obj.event_names,obj.event_stamps] = loadEvents(session);
      if ~isscalar(opt.events) || opt.events ~= "all"
        [~,event_indeces] = intersect(opt.events,obj.event_names,'stable');
        obj.event_stamps = obj.event_stamps(event_indeces);
        unknown_events = setdiff(opt.events,obj.event_names,'stable');
        if ~isempty(unknown_events)
          warning('regions:MissingEvents',"Unable to find events: "+strjoin(unknown_events,', '))
        end
        obj.event_names = obj.event_names(event_indeces);
        obj.all_events = false;
      else
        obj.all_events = true;
      end
      
      % load behavioral-states time stamps
      opt.states = opt.states(~ismember(opt.states,["all","other"])); % remove occurrencies of "all" and "other"
      obj.state_stamps = cell(numel(opt.states)+2,1);
      events_path = session_path + "/";
      new_events_path = "";
      if isfolder(events_path + 'events')
        new_events_path = events_path + 'events/';
        if isfolder(new_events_path + '2021')
          new_events_path = new_events_path + '2021/';
        end
      end
      for i = 1 : numel(opt.states)
        if new_events_path ~= "" && isfile(new_events_path + basename + '.' + opt.states(i))
          obj.state_stamps{i} = readmatrix(new_events_path + basename + '.' + opt.states(i),FileType='text');
        else
          obj.state_stamps{i} = readmatrix(events_path + basename + '.' + opt.states(i),FileType='text');
        end
      end
      obj.states = [opt.states;"all";"other"];  % add "all" and "other" as special states

      % special-states stamps: "all" and "other"
      obj.state_stamps{end-1} = [obj.event_stamps{1}(1),obj.event_stamps{end}(end)]; % all
      obj.state_stamps{end} = obj.state_stamps{end-1}; % other
      for s = obj.state_stamps(1:end-2).'
        obj.state_stamps{end} = SubtractIntervals(obj.state_stamps{end},s{1});
      end

      % validate and assign region ids
      ids = unique(opt.regions);
      if length(ids) ~= length(opt.regions)
        warning('Requested regions contain duplicates.')
      end
      obj.ids = ids;

      % create arrays to store data
      obj.regions_array = region.empty;

      % load spikes
      if opt.load_spikes
        obj = obj.loadSpikes();
      end

      if opt.load_spikes && opt.verbose
        fprintf(1,'Built regions with\nids: '+strjoin(string(obj.ids),', ')+'\nlabels: '+strjoin(regionID2Acr(obj.ids),', ')+'\nstates: '+strjoin(obj.states([1:end-2,end]),', ')+'\n\n')
      end
    end
  end
end