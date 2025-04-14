classdef regions
% regions Class to EXPLAIN, requires FMAToolbox, ISAC, region, brain
%
% properties:
%
% methods:
%
  
properties (GetAccess = public, SetAccess = protected)
  % data
  basename        % session basename, e.g., Rat386-20180918
  session_path    % path to Pietro folder in this session
  results_path    % path to results folder
  rat
  phases
  phase_stamps
  states
  state_stamps
  ids
  regions_array
  % avalanches parameters
  aval_window
  aval_smooth
  aval_threshold
  aval_event_threshold
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
      % load_spikes (1,1) {mustBeLogical} = false    if true, load spikes

      arguments
        session (1,:) char
        opt.results_path (1,1) string = ""
        opt.events (:,1) = "all"
        opt.states (:,1) string = "all"
        opt.regions (:,1) double {mustBeInteger,mustBeNonnegative} = []
        opt.load_spikes (1,1) {mustBeLogical} = false
      end

      % assign members
      [session_path,basename] = fileparts(session);
      obj.basename = basename;
      obj.session_path = append(session_path,'/Pietro');
      if opt.results_path == ""
        opt.results_path = append(obj.session_path,'/AvalanchesByState');
      end
      obj.results_path = opt.results_path;
      obj.rat = str2double(obj.basename(4:6));

      % validate format of option phase REMOVE, SHOULD JUST BE NAMES OF EVENTS
      if iscell(opt.events)
        for phase = opt.events.'
          if ~isnumeric(phase{1})
            error('mustBeNumericOrString:WrongType','Invalid value for ''phases'' argument. Value must be a cell array of numerics or a string array.')
          else
            if ~ismatrix(phase{1}) || size(phase{1},2) ~= 2
              error('mustHaveDims:WrongDim','Invalid value for ''phases'' argument. Value must be a cell array of matrices with two columns.')
            elseif any(any(phase{1}<0))
              error('mustBeNonnegative:Negative','Invalid value for ''phases'' argument. Value must be non negative')
            end
          end
        end
        obj.phase_stamps = opt.events; % keep user defined phase stamps
      else
        if isnumeric(opt.events)
          error('mustBeNumericOrString:WrongType','Invalid value for ''phase'' argument. Value must be a cell array of numerics or a string array.')
        end
        try
          opt.events = string(opt.events);
        catch
          error('mustBeNumericOrString:WrongType','Invalid value for ''phase'' argument. Value must be a cell array of numerics or a string array.')
        end
        % load protocol-phases time stamps required by the user
        obj.phase_stamps = {};
        found_phase = false(numel(opt.events),1);
        if numel(opt.events) ~= 1 || opt.events ~= "all" % SWITCH TO any(opt.events~="all") ?
          [events,stamps] = loadEvents(session);
          for i = 1 : numel(events) % CAN USE ismember HERE
            for j = 1 : numel(opt.events)
              % SHOULD ERROR IF I FIND 2 TIMES SAME PHASE AND WARN IF ORDER OF PHASES IS UNEXPECTED
              if events(i) == opt.events(j)
                obj.phase_stamps{end+1,1} = stamps{i};
                found_phase(j) = true;
              end
            end
          end
        else
          found_phase = true;
        end
        if ~all(found_phase)
          error('regions:MissingEvents','Unable to find all requested events.')
        end
        obj.phases = opt.events;
      end

      % load behavioral-states time stamps IMPORVE: LOAD ALL EVENTS FOUND IN DATA USER NEEDS NOT SPECIFYING THEM AT CREATION AND ORDER IS FIXED
      opt.states = opt.states(opt.states~="all"); % remove occurrencies of "all"
      obj.state_stamps = cell(size(opt.states));
      events_path = append(session_path,'/');
      if isfolder(append(events_path,'events'))
        events_path = append(events_path,'events/');
        if isfolder(append(events_path,'2021'))
          events_path = append(events_path,'2021/');
        end
      end
      other = 0;
      for i = 1 : numel(opt.states)
        if opt.states(i) == "other"
          obj.state_stamps{i} = [0,intmax];
          other = i;
        else
          % IMPLEMENT ALLOWED STATES LIST, TAHT FORCES ORDER OF STATES ALWAYS, NO MORE ORDER PROBLEM!
          obj.state_stamps{i} = readmatrix(append(events_path,basename,'.',opt.states(i)),FileType='text');
        end
      end
      if other ~= 0
        for i = 1 : numel(opt.states)
          if i ~= other
            obj.state_stamps{other} = SubtractIntervals(obj.state_stamps{other},obj.state_stamps{i});
          end
        end
      end
      obj.states = [opt.states;"all"];  % add "all" as last state

      % validate and assign region ids
      ids = unique(opt.regions);
      if length(ids) ~= length(opt.regions)
        warning('Requested regions contain duplicates.')
      end
      obj.ids = ids;

      % create arrays to store data
      obj.regions_array = region.empty;

      % optionally, load spikes
      if opt.load_spikes
        obj = obj.loadSpikes();
      end
    end
  end
end
