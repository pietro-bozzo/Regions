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
  session_path    % path to session folder
  rat
  event_names
  event_stamps
  all_events
  states
  state_stamps
  ids
  regions_array
  cluster_map % i-th row is [electrode group, cluster, channel] for unit i
  % avalanches parameters
  aval_window
  aval_step
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
        opt.shuffle (1,1) {mustBeLogical} = false
        opt.verbose (1,1) {mustBeLogical} = true
      end

      % assign members
      [obj.session_path,obj.basename] = fileparts(session);
      obj.rat = str2double(obj.basename(4:6));

      % load protocol-events time stamps COULD ADD try catch AND HANDLE MISSING .cat.evt FILE AS I DID BEFORE
      try
        [obj.event_names,obj.event_stamps] = loadEvents(session);
        if ~isscalar(opt.events) || opt.events ~= "all"
          [~,event_indeces] = intersect(obj.event_names,opt.events,'stable');
          unknown_events = setdiff(opt.events,obj.event_names,'stable');
          if ~isempty(unknown_events)
            warning('regions:MissingEvents',"Unable to find events: "+strjoin(unknown_events,', '))
          end
          obj.event_names = obj.event_names(event_indeces);
          obj.event_stamps = obj.event_stamps(event_indeces);
          obj.all_events = false;
        else
          obj.all_events = true;
        end
      catch
        obj.event_names = "<missing>";
        obj.event_stamps = {};
        obj.all_events = true;
      end
      
      % load behavioral-states time stamps
      opt.states = opt.states(~ismember(opt.states,["all","other"])); % remove occurrencies of "all" and "other"
      obj.state_stamps = cell(numel(opt.states)+2,1);
      events_path = obj.session_path;
      new_events_path = "";
      if isfolder(fullfile(events_path,'events'))
        new_events_path = fullfile(events_path,'events');
        if isfolder(fullfile(new_events_path,'2021'))
          new_events_path = fullfile(new_events_path,'2021');
        end
      end
      for i = 1 : numel(opt.states)
        if new_events_path ~= "" && isfile(fullfile(new_events_path,obj.basename + "." + opt.states(i)))
          obj.state_stamps{i} = readmatrix(fullfile(new_events_path,obj.basename + "." + opt.states(i)),FileType='text');
        else
          obj.state_stamps{i} = readmatrix(fullfile(events_path,obj.basename + "." + opt.states(i)),FileType='text');
        end
      end
      obj.states = [opt.states;"all";"other"];  % add "all" and "other" as special states

      % special-states stamps: "all" and "other"
      if ~isscalar(obj.event_names) || obj.event_names ~= "<missing>"
        obj.state_stamps{end-1} = [obj.event_stamps{1}(1),obj.event_stamps{end}(end)]; % all
        obj.state_stamps{end} = obj.state_stamps{end-1}; % other
        for s = obj.state_stamps(1:end-2).'
          obj.state_stamps{end} = SubtractIntervals(obj.state_stamps{end},s{1});
        end
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
        obj = obj.loadSpikes(shuffle=opt.shuffle);
      end

      if opt.load_spikes && opt.verbose
        fprintf(1,'Built regions with\nids: '+strjoin(string(obj.ids),', ')+'\nlabels: '+strjoin(regionID2Acr(obj.ids),', ')+'\nstates: '+strjoin(obj.states([1:end-2,end]),', ')+'\n\n')
      end
    end
  end
end