classdef regions
% regions Handles multi-region spiking data, recording session info, and computes quantities per region
% (e.g., firing rates, avalanches, assemblies)

% requires FMAToolbox, ISAC, region

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

properties (GetAccess = public, SetAccess = protected)
  % data
  basename        % session basename, e.g., Rat386-20180918
  session_path    % path to session folder
  rat
  phase
  state
  event
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
      % regions Class constructor
      %
      % arguments:
      %     session         string, path to session .xml file
      %
      % name-value arguments:
      %     legend          string = "", path to .anatomy file, default is nonlateral.anatomy from folder Regions/Data
      %     phases          (:,1) string = "all", names of recording session phases to load
      %     states          (:,1) string = "all", states to load, default aggregates all data in a single state named "all"
      %     events          (:,1) string = "all", other events to load
      %     regions         (:,1) string = [], regions to load, default loads all recorded regions
      %     load_spikes     logical = true, if false, do not load spikes, to access just states and events
      %     mat             logical = false, load spikes from /<basename>/Regions/Data/spikes.mat
      %     shuffle         logical = false, shuffle spikes inside each recording session phase
      %     verbose         logical = true, log progress to console

      arguments
        session (1,1) string
        opt.legend (1,1) string = ""
        opt.phases (:,1) string = "all"
        opt.states (:,1) string = "all"
        opt.events (:,1) string = strings().empty
        opt.regions (:,1) string = []
        opt.load_spikes (1,1) {mustBeLogical} = true
        opt.mat (1,1) {mustBeLogical} = false
        opt.shuffle (1,1) {mustBeLogical} = false
        opt.verbose (1,1) {mustBeLogical} = true
      end

      if ~isfile(session)
        error('regions:sessionFile',"Unable to find "+session)
      end

      % assign members
      [obj.session_path,obj.basename] = fileparts(session);
      obj.rat = str2double(obj.basename{1}(4:6));

      % load recording session time stamps from '<basename>.cat.evt'
      error_flag = false;
      try
        evt = LoadEvents(fullfile(obj.session_path,obj.basename)+".cat.evt",'compact','on');
        obj.phase.names = string(evt.description);
        obj.phase.times = evt.time;
        if ~isscalar(opt.phases) || opt.phases ~= "all"
          [~,phase_indeces] = intersect(obj.phase.names,opt.phases,'stable');
          unknown_phases = setdiff(opt.phases,obj.phase.names,'stable');
          if isempty(phase_indeces)
            error_flag = true;
          elseif ~isempty(unknown_phases)
            warning('regions:MissingEvents',"Unable to find events: "+strjoin(unknown_phases,', '))
          end
          obj.phase.names = obj.phase.names(phase_indeces);
          obj.phase.times = obj.phase.times(phase_indeces);
          obj.phase.all = false;
        else
          obj.phase.all = true;
        end
      catch
        obj.phase.names = string(missing);
        obj.phase.times = {};
        obj.phase.all = true;
      end
      if error_flag
        error('regions:MissingEvents',"Unable to find events: "+strjoin(unknown_phases,', '))
      end
      
      % load behavioral-states time stamps
      opt.states = opt.states(~ismember(opt.states,["all","other"])); % remove occurrencies of "all" and "other"
      obj.state.names = [opt.states;"all";"other"];
      obj.state.times = cell(numel(opt.states)+2,1);
      events_path = obj.session_path;
      new_events_path = ""; % EXTRA for Paris data, to remove
      if isfolder(fullfile(events_path,'events'))
        new_events_path = fullfile(events_path,'events');
        if isfolder(fullfile(new_events_path,'2021'))
          new_events_path = fullfile(new_events_path,'2021');
        end
      end
      for i = 1 : numel(opt.states)
        if new_events_path ~= "" && isfile(fullfile(new_events_path,obj.basename + "." + opt.states(i)))
          obj.state.times{i} = readmatrix(fullfile(new_events_path,obj.basename + "." + opt.states(i)),FileType='text');
        else
          obj.state.times{i} = readmatrix(fullfile(events_path,obj.basename + "." + opt.states(i)),FileType='text');
        end
      end
      % special-states stamps: "all" and "other"
      if ~isscalar(obj.phase.names) || ~ismissing(obj.phase.names)
        obj.state.times{end-1} = [obj.phase.times{1}(1),obj.phase.times{end}(end)]; % all
        obj.state.times{end} = obj.state.times{end-1}; % other
        for s = obj.state.times(1:end-2).'
          obj.state.times{end} = SubtractIntervals(obj.state.times{end},s{1});
        end
      end

      % load other events
      opt.events = cellfun(@(x) strsplit(x,'/'),cellstr(opt.events),'UniformOutput',false);
      obj.event.names = string(cellfun(@(x) x{end},opt.events,'UniformOutput',false));
      obj.event.times = cell(numel(opt.events),1);
      obj.event.values = cell(numel(opt.events),1);
      for i = 1 : numel(opt.events)
        fname = fullfile(obj.session_path,opt.events{i}{1:end-1},obj.basename + "." + opt.events{i}{end});
        obj.event.values{i,1} = readmatrix(fname,FileType='text');
        if ismember(obj.event.names(i),["ripples","spindles"])
          obj.event.times{i,1} = obj.event.values{i,1}(:,[1,3]);
        else
          obj.event.times{i,1} = obj.event.values{i,1}(:,1:2);
        end
      end

      % validate and assign region ids
      obj.ids = unique(opt.regions,'stable');

      % create array to store data
      obj.regions_array = region.empty;

      % load spikes
      if opt.load_spikes
        obj = obj.loadSpikes('legend',opt.legend,'shuffle',opt.shuffle,'mat',opt.mat);
      end

      if opt.load_spikes && opt.verbose
        fprintf(1,"Built regions with\nids: "+strjoin(string(obj.ids),', ')+'\nstates: '+strjoin(obj.state.names([1:end-2,end]),', ')+'\n\n')
      end
    end
  end
end