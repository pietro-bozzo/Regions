classdef brain
  % brain Summary of this class goes here
  %   Detailed explanation goes here

  properties % (Access = private)
    % data
    %basename
    %path
    state
    % Indipendent Component Analysis
    IC_window
    IC_weights % cell array of IC weights
    IC_time
    ICs_activations
    IC_bin_size
    ICs_binar_activity
    % avalanches
    aval_threshold
    aval_indeces
    aval_profile
    aval_sizes
    aval_timeDependendentSize
  end

  methods
      function obj = brain(IC_weights,IC_window,IC_time,ICs_activations,opt)
      % region Construct an instance of this class
      %   Detailed explanation goes here
      arguments
        %basename (1,1) string = ""
        %path (1,1) string = ""
        IC_weights (:,1) cell = []
        IC_window (1,1) double = []
        IC_time (:,1) double = []
        ICs_activations (:,2) double = []
        opt.state (1,1) string = "all"
      end
      %obj.basename = basename;
      %obj.path = path;
      obj.state = opt.state;
      obj.IC_weights = IC_weights;
      obj.IC_window = IC_window;
      obj.IC_time = IC_time;
      obj.ICs_activations = ICs_activations;
    end

    % setter methods

    function this = setNeurons(this,neurons)
      this.neurons = neurons;
    end

    % getter methods

    function state = getState(this)
      state = this.state;
    end

    function neurons = getNeurons(this)
      neurons = this.neurons;
    end

    function dt = getRateDt(this)
      dt = this.rate_dt;
    end

    function window = getRateWindow(this)
      window = this.rate_window;
    end

    function threshold = getAvalThreshold(this)
      threshold = this.aval_threshold;
    end

    function indeces = getAvalIndeces(this)
      indeces = this.aval_indeces;
    end

  end
end