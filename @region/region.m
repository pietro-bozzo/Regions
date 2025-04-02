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
    spike_dt % TO REMOVE
    aval_threshold % TO REMOVE
    aval_indeces % TO REMOVE
    aval_profile % TO REMOVE
    aval_sizes
    aval_intervals
    aval_timeDependendentSize
    % assemblies
    assemblies
    asmb_weights
    asmb_activations
  end

  methods
    function obj = region(id,neurons,spikes)
      % region Construct an instance of this class
      %   Detailed explanation goes here
      arguments
        id (1,1) double {mustBeInteger} = -1 % uninitialized value
        neurons (:,1) double {mustBeInteger,mustBePositive} = []
        spikes (:,2) double = []
      end
      obj.id = id;
      obj.n_neurons = numel(neurons);
      obj.neurons = neurons;
      obj.spikes = spikes;
    end

    % methods to compute properties

    function maxes = binMaxAvalanches(this,bin_size)
      arguments
        this (1,1) region
        bin_size (1,1) double {mustBePositive} % IN seconds
      end
      if any(isnan(this.aval_indeces))
        maxes = NaN;
      else
        times = this.getAvalTimes();
        bin_indeces = discretize(times,0:bin_size:max(times)+bin_size);
        sorted_bins = sortrows([bin_indeces,this.aval_sizes],'descend');
        [~,max_ind] = unique(sorted_bins(:,1));
        maxes = sorted_bins(max_ind,2);
      end
    end
        
  end
end