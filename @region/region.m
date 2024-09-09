classdef region
  % region Summary of this class goes here
  %   Detailed explanation goes here

  properties % (Access = private)
    % data
    basename
    path
    id
    state
    n_neurons
    neurons
    spikes
    % avalanches
    spike_dt
    aval_threshold
    aval_indeces
    aval_profile
    aval_sizes
    % assemblies
    %time_window % default 0.03
    %asmb_threshold % default 2/3
    %assemblies
    %asmb_sizes
    %asmb_raster
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
        opt.n_neurons (1,1) double {mustBeInteger,mustBeNonnegative} = 0
      end
      obj.basename = basename;
      obj.path = path;
      obj.id = id;
      obj.state = opt.state;
      obj.neurons = neurons;
      if isempty(neurons)
        obj.n_neurons = opt.n_neurons;
      else
        obj.n_neurons = numel(neurons);
      end
      obj.spikes = spikes;
    end

    % setter methods

    function this = setNeurons(this,neurons)
      this.neurons = neurons;
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

    % getter methods

    function id = getId(this)
      id = this.id;
    end

    function state = getState(this)
      state = this.state;
    end

    function n = getNNeurons(this)
      n = this.n_neurons;
    end

    function neurons = getNeurons(this)
      neurons = this.neurons;
    end

    function spikes = getSpikes(this)
      spikes = this.spikes;
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

    function dt = getSpikeDt(this)
      dt = this.spike_dt;
    end

    function threshold = getAvalThreshold(this)
      threshold = this.aval_threshold;
    end

    function indeces = getAvalIndeces(this)
      indeces = this.aval_indeces;
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

    function intervals = getAvalIntervals(this,opt)
      arguments
        this (1,1) region
        opt.restriction (:,1) double = []
        opt.threshold (1,1) double = 0
      end
      intervals = (this.aval_indeces-repmat([1,0],numel(this.aval_indeces(:,1)),1)) * this.spike_dt;
      if opt.threshold ~= 0
        intervals = intervals(this.aval_sizes>opt.threshold,:);
      end
      if ~isempty(opt.restriction)
        intervals = intervals(intervals(:,1)>opt.restriction(1) & intervals(:,2)<opt.restriction(2),:);
      end
    end

    function sizes = getAvalSizes(this,opt)
      arguments
        this (1,1) region
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
        opt.spike_dt (1,1) double {mustBePositive} = 0.02
        opt.threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(opt.threshold,1)} = 0
      end
      this.spike_dt = opt.spike_dt;
      this.aval_threshold = opt.threshold;
      [this.aval_sizes,this.aval_profile,this.aval_indeces] = getAvalanchesFromList( ...
        this.spikes,this.spike_dt,threshold=opt.threshold);
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