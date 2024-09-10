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
    phase
    states
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
      % phase (1,1) string = "all"
      % states (:,1) string = "all"
      % load_spikes (1,1) {mustBeLogical} = false    if true, force load of spikes
      arguments
        session (1,:) char
        opt.results_path (1,1) string = ""
        opt.phase (1,1) string = "all"
        opt.states (:,1) string = "all"
        opt.regions (:,1) double {mustBeInteger,mustBeNonnegative} = []
        opt.load_spikes (1,1) {mustBeLogical} = false
      end
      [path,obj.basename] = fileparts(session);
      obj.session_path = append(path,'/Pietro');
      if opt.results_path == ""
        opt.results_path = append(obj.session_path,'/AvalanchesByState');
      end
      obj.results_path = opt.results_path;
      obj.rat = str2double(obj.basename(4:6));
      obj.phase = opt.phase;
      obj.states = opt.states;
      ids = unique(opt.regions);
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
