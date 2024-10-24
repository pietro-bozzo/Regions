classdef region
  % region Summary of this class goes here
  %   Detailed explanation goes here

  properties (GetAccess = public, SetAccess = protected)
    % data
    basename
    path
    id
    state
    spikes    % matrix having sorted time stamps as first column and unit ids as second
    % avalanches
    spike_dt
    aval_threshold
    aval_indeces
    aval_profile
    aval_sizes
    aval_timeDependendentSize
    % assemblies
    %time_window % default 0.03
    %asmb_threshold % default 2/3
    %assemblies
    %asmb_sizes
    %asmb_raster
    IC_weights % cell array of IC weights
    IC_window
    IC_time
    ICs_activity
    ICaval_threshold
    ICaval_indeces
    ICaval_profile
    ICaval_sizes
    ICaval_timeDependendentSize
    npc
    explainedVariance
  end

  properties (Access = public)
      neurons
  end

  properties (Dependent)
      n_neurons
  end

  methods
    function obj = region(basename,path,id,neurons,spikes,opt)
      % region Construct an instance of this class
      %   Detailed explanation goes here
      arguments
        basename (1,1) string = ""
        path (1,1) string = ""
        id (1,1) double {mustBeInteger} = -1
        neurons (:,1) double = []
        spikes (:,2) double = []
        opt.state (1,1) string = "all"
      end
      obj.basename = basename;
      obj.path = path;
      obj.id = id;
      obj.state = opt.state;
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

    function this = setAssemblies(this,assemblies,time_window)

      % setAssemblies Set assemblies, asmb_sizes and time window
      this.assemblies = assemblies;
      this.time_window = time_window;
      this.asmb_sizes = sum(assemblies,2);
      spike_raster = getSpikeRaster(this.spikes,bin_size=time_window); % RAGIONA MEGLIO SU QUESTO
      this.asmb_raster = sparse(this.assemblies) * spike_raster;
      this.asmb_raster = (this.asmb_raster./sum(this.assemblies,2)) >= this.asmb_threshold;
    end

    function this = setICComponents(this, IC_weights, IC_window, IC_time, ICs_activity)
        this.IC_weights = IC_weights;
        this.IC_window = IC_window;
        this.IC_time = IC_time;
        this.ICs_activity = ICs_activity;
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

    function this = computeAvalanches(this,opt)
      arguments
        this (1,1) region
        opt.spike_dt (1,1) double {mustBePositive} = 0.01
        opt.threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(opt.threshold,1)} = 0
        opt.dopc = false
        opt.pc = NaN
        opt.var = 0.5
        opt.first = true
        opt.pcPercentile = 10
      end
      if opt.dopc
          n0 = getSpikesMatrix(this.spikes,windowsize=opt.spike_dt);
          [Z, pc, explained] = reconstructPCSpikesMatrix(n0, pc=opt.pc, var=opt.var, first=opt.first);
          [this.aval_sizes,this.aval_profile,this.aval_indeces, this.aval_timeDependendentSize] = getAvalanchesFromMatrix(Z, percentile=opt.pcPercentile);
          this.npc = pc;
          this.explainedVariance = explained;
      else
      this.spike_dt = opt.spike_dt;
      this.aval_threshold = opt.threshold;
      [this.aval_sizes,this.aval_profile,this.aval_indeces, ~, this.aval_timeDependendentSize] = getAvalanchesFromList( ...
        this.spikes,this.spike_dt,threshold=opt.threshold);
      end
    end

    function this = computeICAvalanches(this, opt)
    arguments
      this (1,1) region
      opt.threshold (1,1) double {mustBeNonnegative} = 2
    end
        if ~isempty(this.ICs_activity)
            profile = sum(abs(zscore(this.ICs_activity))>opt.threshold,2);
            this.ICaval_profile = profile;
            ind = [true;profile(2:end)~=0|profile(1:end-1)~=0]; % ind(i) = 0 if i is repeated zero
            % compute sizes
            clean = profile(ind); % remove repeated zeros
            this.ICaval_sizes = accumarray(cumsum(clean==0)+(profile(1)~=0),clean);
            if this.ICaval_sizes(end) == 0 % remove last zero
              this.ICaval_sizes = this.ICaval_sizes(1:end-1);
            end
            % compute indeces of avalanche initiation and ending times
            this.ICaval_indeces = [find([profile(1)~=0;profile(2:end)~=0&profile(1:end-1)==0]), ...
              find([profile(2:end)==0&profile(1:end-1)~=0;profile(end)~=0])];
            this.ICaval_timeDependendentSize = clean;
        else
            [this.ICaval_profile, this.ICaval_sizes, this.ICaval_indeces, this.ICaval_timeDependendentSize] = deal(NaN);
        end
    end

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
        
    function this = computeAssemblies(this,opt)
      arguments
        this (1,1) region
        opt.time_window (1,1) double {mustBeNonnegative} = 0
        opt.load (1,1) {mustBeLogical} = false
        opt.save (1,1) {mustBeLogical} = false
      end
      if opt.time_window ~= 0
        this.time_window = opt.time_window;
      end
      % set up file to load and save assemblies
      asmb_file = append(this.basename,'.asb.',num2str(this.id,'%02d'));
      if ~strcmp(this.state,"all")
        asmb_file = append(asmb_file,'.',this.state);
      end
      asmb_path = append(this.path,'/Assemblies/',asmb_file);
      % compute assemblies
      if opt.load
        try % try loading assemblies
          this.assemblies = readmatrix(asmb_path,FileType='text');
          this.asmb_sizes = sum(this.assemblies,2);
        catch except
          if strcmp(except.identifier,'MATLAB:textio:textio:FileNotFound')
            opt.load = false; % flag for failed loading, to enable saving if required
            if opt.save
              fprintf(1,append('Unable to load ',asmb_file,', it will be computed and saved.\n'));
            else
              save = input(append('Unable to load ',asmb_file,', it will be computed. Save it? [y,n]: '),'s');
              switch save
                case 'y', opt.save = true;
                case 'n'
                otherwise, fprintf(1,'Unrecognized input, assemblies won''t be saved.\n');
              end
            end
            [this.assemblies,this.asmb_sizes] = callISAC(this.spikes,time_window=this.time_window);
          else
            throw(except);
          end
        end
      else
        [this.assemblies,this.asmb_sizes] = callISAC(this.spikes,time_window=this.time_window);
      end
      if isempty(this.assemblies) % no assemblies detected, adjust n of columns to match n of neurons
        this.assemblies = zeros(0,length(unique(this.spikes(:,2))));
      end
      if ~opt.load && opt.save
        writematrix(this.assemblies,asmb_path,FileType='text');
      end
    end

    function this = computeAsmbRaster(this,opt)
      arguments
        this (1,1) region
        opt.threshold (1,1) double {mustBeNonnegative} = 0
      end
      if opt.threshold ~= 0
        this.asmb_threshold = opt.threshold;
      end
      spike_raster = getSpikeRaster(this.spikes,bin_size=this.time_window); % RAGIONA MEGLIO SU QUESTO
      this.asmb_raster = sparse(this.assemblies) * spike_raster;
      this.asmb_raster = (this.asmb_raster./sum(this.assemblies,2)) >= this.asmb_threshold;
    end
  end
end