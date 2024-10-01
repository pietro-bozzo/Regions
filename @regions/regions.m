classdef regions
  % regions Class to EXPLAIN, requires FMAToolbox, ISAC, region, brain
  %
  % properties:
  %
  % methods:
  %
  
  properties (GetAccess = public, SetAccess = protected)
    % data
    basename   % session basename, e.g., Rat386-20180918
    session_path    % path to Pietro folder in this session
    results_path    % path to results folder
    rat
    phases
    phase_stamps
    states
    state_stamps
    ids
    regions_array
    brain_array
  end
  
  methods
    function obj = regions(session,opt)
      % regions Construct an instance of this class
      %
      % arguments:
      % session (1,:) char
      % results_path (1,1) string = ""
      % phases (1,1) string = "all"   either a cell of n x 2 matrices of time stamps or names of protocol
      %                               phases
      % states (:,1) string = "all"
      % load_spikes (1,1) {mustBeLogical} = false    if true, load spikes

      arguments
        session (1,:) char
        opt.results_path (1,1) string = ""
        opt.phases (:,1) = "all"
        opt.states (:,1) string = "all"
        opt.regions (:,1) double {mustBeInteger,mustBeNonnegative} = []
        opt.load_spikes (1,1) {mustBeLogical} = false
      end

      [session_path,obj.basename] = fileparts(session);
      obj.session_path = append(session_path,'/Pietro');
      if opt.results_path == ""
        opt.results_path = append(obj.session_path,'/AvalanchesByState');
      end
      obj.results_path = opt.results_path;
      obj.rat = str2double(obj.basename(4:6));
      % validate format of option phase
      if iscell(opt.phases)
        for phase = opt.phases.'
          if ~isnumeric(phase{1})
            error('mustBeNumericOrString:wrongType',['Invalid value for ''phases'' argument. Value must be' ...
              ' a cell array of numerics or string.'])
          else
            if ~ismatrix(phase{1}) || size(phase{1},2) ~= 2
              error('mustHaveDims:wrongDim',['Invalid value for ''phases'' argument. Value must be a ' ...
                'cell array of matrices with two columns.'])
            elseif any(any(phase{1}<0))
              error('mustBeNonnegative:negative',['Invalid value for ''phases'' argument. Value must be ' ...
                'non negative'])
            end
          end
        end
        obj.phase_stamps = opt.phases; % keep user defined phase stamps
      else
        if isnumeric(opt.phases)
          error('mustBeNumericOrString:wrongType',['Invalid value for ''phase'' argument. Value must be' ...
            ' a cell array of numerics or string.'])
        end
        try
          opt.phases = string(opt.phases);
        catch
          error('mustBeNumericOrString:wrongType',['Invalid value for ''phase'' argument. Value must be' ...
            ' a cell array of numerics or string.'])
        end
        % load protocol-phases time stamps required by the user
        obj.phase_stamps = {};
        found_phase = false(numel(opt.phases),1);
        if numel(opt.phases) ~= 1 || opt.phases ~= "all"
          events = LoadEvents(append(session_path,'/',obj.basename,'.cat.evt'));
          for i = 1 : 2 : numel(events.description)
            for j = 1 : numel(opt.phases)
              % SHOULD ERROR IF I FIND 2 TIMES SAME PHASE AND WARN IF ORDER OF PHASES IS UNEXPECTED
              % bis IS BEIGN IGNORED NOW
              if strcmp(events.description{i}(end-strlength(opt.phases(j))+1:end),opt.phases(j))
                if ~strcmp(events.description{i+1}(end-strlength(opt.phases(j))+1:end),opt.phases(j))
                  error('regions:WrongEventsFormat',append('Unable to find two time stamps for ', ...
                    opt.phases(j),'.'))
                end
                obj.phase_stamps{end+1,1} = [events.time(i),events.time(i+1)];
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
        obj.phases = opt.phases;
      end
      % load behavioral-states time stamps
      obj.state_stamps = cell(size(opt.states));
      events_path = append(session_path,'/events/');
      if isfolder(append(events_path,'2021'))
        events_path = append(events_path,'2021/');
      end
      awake = 0;
      for i = 1 : numel(opt.states)
        if opt.states(i) == "awake"
          obj.state_stamps{i} = [0,intmax];
          awake = i;
        elseif opt.states(i) ~= "all"
          % IMPLEMENT ALLOWED STATES LIST, TAHT FORCES ORDER OF STATES ALWAYS, NO MORE ORDER PROBLEM!
          obj.state_stamps{i} = readmatrix(append(events_path,obj.basename,'.',opt.states(i)), ...
            FileType='text');
        end
      end
      if awake ~= 0 % AWAKE IS A BAD NAME FOR THIS IMPLEMENTATION
        for i = 1 : numel(opt.states)
          if i ~= awake && opt.states(i) ~= "all"
            obj.state_stamps{awake} = SubtractIntervals(obj.state_stamps{awake},obj.state_stamps{i});
          end
        end
      end
      obj.states = opt.states;
      ids = unique(opt.regions); % DONE TO LIMIT REGIONS TO LOAD, MAYBE REMOVE FOR SIMPLICITY
      if length(ids) ~= length(opt.regions)
        warning('Requested regions contain duplicates.')
      end
      if ~isempty(ids) && ids(1) == 0
        ids = [ids(2:end);0];
      end
      obj.ids = ids;
      obj.regions_array = region.empty;
      obj.brain_array = brain.empty;
      if opt.load_spikes
        obj = obj.loadSpikes();
      end
    end
  end
end
