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

    function [rate,times] = getFiringRate(this,step,bin_size,opt) % OLD FIRING RATE CODE
      % getFiringRate Get firing rate as the number of spikes recorded in sliding windows of size bin_size
      % separated by intervals of size step, not normalized
      arguments
        this (1,1) region
        step (1,1) double {mustBePositive}
        bin_size (1,1) double {mustBePositive}
        opt.restriction (:,1) double = []
      end
      % SHOULD ERROR IF NO SPIKES OR no DT OR NEUR
      [n,k] = rat(bin_size/step); % approximate bin_size/step as a ratio to identify a discretization window
      times = 0 : bin_size/n : this.spikes(end,1)+bin_size/n; % edges of the discretization
      if ~isempty(opt.restriction)
        times = times(times>=opt.restriction(1) & times<=opt.restriction(2));
      end
      rate = histcounts(this.spikes(:,1),times).';
      rate = movmean(rate,n) * n; % compute number of spikes in every sliding window
      rate = rate(1:k:end); % keep only windows separated by 'step' milliseconds
      times = times(1:k:end).';
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