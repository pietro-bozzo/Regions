classdef region
  % region Summary of this class goes here
  %   Detailed explanation goes here

  properties (GetAccess = public, SetAccess = protected)
    % data
    id
    n_neurons
    neurons
    spikes    % matrix having sorted time stamps as first column and unit ids as second
    % avalanches
    aval_sizes
    aval_intervals
    aval_profile
    aval_timeDependendentSize % TO REMOVE
    % assemblies
    assemblies
    asmb_weights
    asmb_activations

    npc
    explainedVariance
  end

  methods
    function obj = region(id,neurons,spikes)
      % region Construct an instance of this class
      %   Detailed explanation goes here
      arguments
        id (1,1) {mustBeNumeric,mustBeInteger} = -1 % uninitialized value
        neurons (:,1) {mustBeNumeric,mustBeInteger,mustBePositive} = []
        spikes (:,2) {mustBeNumeric} = []
      end
      obj.id = id;
      obj.n_neurons = numel(neurons);
      obj.neurons = neurons;
      obj.spikes = spikes;
    end      
  end
end