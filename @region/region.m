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
    spike_dt
    aval_threshold
    aval_indeces
    aval_profile
    aval_sizes
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
        id (1,1) double {mustBeInteger} = -1
        neurons (:,1) double = []
        spikes (:,2) double = []
      end
      obj.id = id;
      obj.n_neurons = numel(neurons);
      obj.neurons = neurons;
      obj.spikes = spikes;
    end

    % setter methods

    function this = set.neurons(this, val)
        arguments
            this
            val (:,1) double
        end
        this.neurons = val;
    end

    function this = setAvalanches(this,dt,threshold,indeces,sizes)
      arguments
        this (1,1) region
        dt (1,1) double {mustBePositive}
        threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(threshold,1)}
        indeces (:,2) double
        sizes (:,1) double
      end
      this.spike_dt = dt;
      if any(isnan(indeces))
        [this.aval_threshold,this.aval_sizes] = deal(NaN);
        this.aval_indeces = [NaN,NaN];
      else
        this.aval_threshold = threshold;
        this.aval_indeces = indeces;
        this.aval_sizes = sizes;
      end
    end

    % getter methods

    function n = get.n_neurons(this)
        n = numel(this.neurons);
    end

    function [rate,times] = getFiringRate(this,step,bin_size,opt)
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

    function times = getAvalTimes(this,opt) % SHOULD ERROR IF NO avals OR no DT
      arguments
        this (1,1) region
        opt.full (1,1) {mustBeLogical} = false % if true, get also times without aval
      end
      if opt.full
        times = this.spike_dt/2 : this.spike_dt : (this.aval_indeces(end)-0.5)*this.spike_dt;
      else
        times = this.aval_indeces(:,1) * this.spike_dt - this.spike_dt/2;
      end
    end

    function durations = getAvalDurations(this,opt) % CHANGE
      arguments
        this (1,1) region
        opt.full (1,1) {mustBeLogical} = false % if true, get also zeros for all times without aval
      end
      if opt.full
        durations = zeros(this.aval_indeces(end),1);
        durations(this.aval_indeces(:,1)) = this.aval_durations;
      else
        durations = this.aval_durations;
      end
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