classdef brain
  % brain Summary of this class goes here
  %   Detailed explanation goes here

  properties % (Access = private)
    % data
    basename
    path
    state
    neurons % CHANGE TO ICs
    rate_dt % CHANGE TO PARAMETERS OF ICA RATHER THAN PARAMETERS OF FIRING RATE
    rate_window % CHANGE TO PARAMETERS OF ICA RATHER THAN PARAMETERS OF FIRING RATE
    firing_rates % CHANGE TO ICs_activity
    % avalanches
    aval_threshold
    aval_indeces
    aval_profile
    aval_sizes
    ATM
  end

  methods
      function obj = brain(basename,path,neurons,dt,window,firing_rates,opt)
      % region Construct an instance of this class
      %   Detailed explanation goes here
      arguments
        basename (1,1) string = ""
        path (1,1) string = ""
        neurons (:,1) double = []
        dt (:,1) double = []
        window (:,1) double = []
        firing_rates (:,:) double = []
        opt.state (1,1) string = "all"
      end
      obj.basename = basename;
      obj.path = path;
      obj.state = opt.state;
      obj.neurons = neurons;
      obj.rate_dt = dt;
      obj.rate_window = window;
      obj.firing_rates = firing_rates;
    end

    % setter methods

    function this = setNeurons(this,neurons)
      this.neurons = neurons;
    end

    function this = setAvalanches(this,dt,threshold,indeces,sizes)
      arguments
        this (1,1) brain
        dt (1,1) double {mustBePositive}
        threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(threshold,1)}
        indeces (:,2) double
        sizes (:,1) double
      end
      if any(isnan(indeces))
        [this.rate_dt,this.aval_threshold,this.aval_sizes] = deal(NaN);
        this.aval_indeces = [NaN,NaN];
      else
        this.rate_dt = dt;
        this.aval_threshold = threshold;
        this.aval_indeces = indeces;
        this.aval_sizes = sizes;
      end
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

    function rates = getFiringRates(this,opt)
      arguments
        this (1,1) brain
        opt.binarize (1,1) {mustBeLogical} = false
      end
      rates = this.firing_rates;
      if opt.binarize
        rates = abs(zscore(this.firing_rates)) > this.aval_threshold;
      end
    end

    function threshold = getAvalThreshold(this)
      threshold = this.aval_threshold;
    end

    function indeces = getAvalIndeces(this)
      indeces = this.aval_indeces;
    end

    function times = getAvalTimes(this,opt) % SHOULD ERROR IF NO avals OR no DT
      arguments
        this (1,1) brain
        opt.full (1,1) {mustBeLogical} = false % if true, get also times without aval
      end
      if opt.full
        times = this.rate_dt/2 : this.rate_dt : (this.aval_indeces(end)-0.5)*this.rate_dt;
      else
        times = this.aval_indeces(:,1) * this.rate_dt - this.rate_dt/2;
      end
    end

    function intervals = getAvalIntervals(this,opt)
      arguments
        this (1,1) brain
        opt.restriction (:,1) double = []
        opt.threshold (1,1) double = 0
      end
      intervals = (this.aval_indeces-repmat([1,0],numel(this.aval_indeces(:,1)),1)) * this.rate_dt;
      if opt.threshold ~= 0
        intervals = intervals(this.aval_sizes>opt.threshold,:);
      end
      if ~isempty(opt.restriction)
        intervals = intervals(intervals(:,1)>opt.restriction(1) & intervals(:,2)<opt.restriction(2),:);
      end
    end

    function sizes = getAvalSizes(this,opt)
      arguments
        this (1,1) brain
        opt.full (1,1) {mustBeLogical} = false % if true, get also zeros for all times without aval
      end
      if ~any(isnan(this.aval_sizes)) && opt.full
        sizes = zeros(this.aval_indeces(end),1);
        sizes(this.aval_indeces(:,1)) = this.aval_sizes;
      else
        sizes = this.aval_sizes;
      end
    end

    function durations = getAvalDurations(this,opt) % CHANGE
      arguments
        this (1,1) brain
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

    function this = computeAvalanches(this,opt)
      arguments
        this (1,1) brain
        opt.threshold (1,1) double {mustBeNonnegative} = 0
      end
      this.aval_threshold = opt.threshold;
      profile = sum(abs(zscore(this.firing_rates))>opt.threshold,2); % CHECK DIM
      this.aval_profile = profile;
      ind = [true;profile(2:end)~=0|profile(1:end-1)~=0]; % ind(i) = 0 if i is repeated zero
      % compute sizes
      clean = profile(ind); % remove repeated zeros
      this.aval_sizes = accumarray(cumsum(clean==0)+(profile(1)~=0),clean);
      % compute durations
      %clean = profile(ind) > 0; % remove repeated zeros and count each active bin as 1
      %durations = accumarray(cumsum(clean==0)+(profile(1)~=0),clean);
      if this.aval_sizes(end) == 0 % remove last zero
        this.aval_sizes = this.aval_sizes(1:end-1);
        %durations = durations(1:end-1);
      end
      % compute indeces of avalanche initiation and ending times
      this.aval_indeces = [find([profile(1)~=0;profile(2:end)~=0&profile(1:end-1)==0]), ...
        find([profile(2:end)==0&profile(1:end-1)~=0;profile(end)~=0])];
    end

    function this = computeATM(this) % SHOULD THE COMPUTED P BE ADJUSTED FOR AVAL SIZE?
      arguments
        this (1,1) brain
      end
      Z = (abs(zscore(this.firing_rates)) > this.aval_threshold).'; % binarized firing rate
      X = reshape(Z(:,2:end),size(Z,1),1,size(Z,2)-1); % columns 2 to end of Z
      Y = reshape(Z(:,1:end-1),1,size(Z,1),size(Z,2)-1); % columns 1 to end - 1 of Z
      At = X.*Y; % Aijt = 1 iff Zi(t+1) = 1 and Zjt = 1
      profile = sum(Z,1).'; % avalanches profile
      start = find([profile(1)~=0;profile(2:end)~=0&profile(1:end-1)==0]);
      stop =  find([profile(2:end)==0&profile(1:end-1)~=0;profile(end)~=0]);
      A = zeros(size(At,1),size(At,2),numel(start));
      for i = 1 : numel(start)
        % Aijk: n of times Zi(t+1) = 1 when Zjt = 1 in aval k
        A(:,:,i) = sum(At(:,:,start(i):stop(i)-1),3);
        % Bj: number of times when Zjt = 1
        Bj = sum(Z(:,start(i):stop(i)-1),2).';
        A(:,:,i) = A(:,:,i) ./ repmat(Bj,numel(Bj),1);
      end
      this.ATM = mean(A,3,"omitnan");
      % MAYBE FASTER METHOD, REQUIRES IMPLEMENTING ACCUMARRAY IN 3D
      %profile = sum(Z,2); % avalanches profile  % CHECK DIM
      %ind = [true;profile(2:end)~=0|profile(1:end-1)~=0]; % ind(i) = 0 if i is repeated zero
      %A_clean = At(:,:,ind); % remove repeated zeros
      % Aijk: n of times Zi(t+1) = 1 when Zjt = 1 in aval k
      %A = accumarray(cumsum(A_clean==0)+(profile(1)~=0),A_clean);
    end
  end
end