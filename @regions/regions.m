classdef regions
  % regions Class to EXPLAIN, requires FMAToolbox, ISAC, region, brain
  %
  % properties:
  %
  % methods:
  %
  
  properties
    % data
    basename        % session basename, e.g., Rat386-20180918
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

    % methods to compute properties

    function maxes = binMaxAvalanches(this,bin_size,opt)
      arguments
        this (1,1) regions
        bin_size (1,1) double {mustBePositive}
        opt.states (:,1) string = []
        opt.regions (:,1) double = []
      end
      [i_indeces,j_indeces] = this.getIndeces(opt.states,opt.regions,strict=false);
      maxes = [];
      for i = i_indeces
        for j = j_indeces
          maxes = [maxes;this.regions_array(i,j).binMaxAvalanches(bin_size)];
        end
      end
    end

    function this = computeATMs(this)
      arguments
        this (1,1) regions
      end
      for i = 1 : numel(this.brain_array)
        this.brain_array(i) = this.brain_array(i).computeATM();
      end
    end

    function this = computeAsmbRasters(this,opt)
      arguments
        this (1,1) regions
        opt.threshold (1,1) double {mustBeNonnegative} = 0
      end
      for i = 1 : numel(this.regions_array)
        this.regions_array(i) = this.regions_array(i).computeAsmbRaster(threshold=opt.threshold);
      end
    end

    % plotting methods

    function plotAvalanches(this,opt)
      arguments
        this (1,1) regions
        opt.states (:,1) string = []
        opt.regions (:,1) double = []
        opt.save (1,1) {mustBeLogical} = false
        opt.show (1,1) {mustBeLogical} = false
      end
      % find requested states and regions
      [j_indeces,i_indeces,opt.states] = this.getIndeces(opt.states,opt.regions);
      % plot figures
      for i = i_indeces
        fig = figure(Name=string(this.ids(i)),NumberTitle='off',Position=get(0,'Screensize'));
        hold on
        title(append('Avalanches for ',this.basename,', ',regionID2Acr(this.ids(i))), ...
            FontSize=17);
        subtitle(append('n units: ',string(size(this.regions_array(1,i).neurons,1)),', Δt: ', ...
          string(this.regions_array(1,i).spike_dt)),FontSize=14);
        xlabel('t (h)',FontSize=14);
        ylabel('S (# spikes)',FontSize=14);
        set(gca,XLimSpec='Tight',TickDir='out')
        for j = j_indeces
          reg = this.regions_array(j,i);
          plot(reg.getAvalTimes(full=true)/3600,reg.getAvalSizes(full=true));
        end
        legend(opt.states);
        if opt.save
          saveas(fig,append(this.results_path,'/aval_state.',string(this.regions_array(1,i).id),'.svg'), ...
            'svg')
        end
        if ~opt.show
          close(fig)
        end
      end
    end

    function plotAvalancheDistributions(this,opt)
      arguments
        this (1,1) regions
        opt.states (:,1) string = []
        opt.regions (:,1) double = []
        opt.save (1,1) {mustBeLogical} = false
        opt.show (1,1) {mustBeLogical} = false
      end
      % find requested states and regions
      [j_indeces,i_indeces,opt.states,opt.regions] = this.getIndeces(opt.states,opt.regions);
      % plot figures
      for i = i_indeces
        fig = figure(Name=string(this.ids(i)),NumberTitle='off',Position=get(0,'Screensize'));
        hold on
        for j = j_indeces
          [counts,edges] = histcounts(this.regions_array(j,i).getAvalSizes(),Normalization='pdf');
          stairs(edges(counts~=0),counts(counts~=0),LineWidth=0.85)
          set(gca,Xscale='log',Yscale='log',TickDir='out')
        end
        title(append('Avalanche size distributions for ',this.basename,', ',regionID2Acr( ...
          this.ids(i))),FontSize=17);
        subtitle(append('n units: ',string(size(this.regions_array(1,i).neurons,1)),', Δt: ', ...
          string(this.regions_array(1,i).spike_dt)),FontSize=14);
        xlabel('S',FontSize=14);
        ylabel('p(S)',FontSize=14);
        set(gca,TickDir='out')
        legend(opt.states);
        if opt.save
          saveas(fig,append(this.results_path,'/size_distr.',string(this.ids(i)),'.svg'),'svg')
        end
        if ~opt.show
          close(fig)
        end
      end
    end

    function plotAvalDistrByState(this,opt)
      arguments
        this (1,1) regions
        opt.states (:,1) string = []
        opt.regions (:,1) double = []
        opt.save (1,1) {mustBeLogical} = false
        opt.show (1,1) {mustBeLogical} = false
      end
      % find requested states and regions
      [j_indeces,i_indeces] = this.getIndeces(opt.states,opt.regions);
      % plot figures
      for j = j_indeces
        fig = figure(Name=this.states(j),NumberTitle='off',Position=get(0,'Screensize')); hold on
        labels = regionID2Acr(this.ids);
        for i = i_indeces
          [counts,edges] = histcounts(this.regions_array(j,i).getAvalSizes(),Normalization='pdf');
          stairs(edges(counts~=0),counts(counts~=0),LineWidth=0.85)
          set(gca,Xscale='log',Yscale='log',TickDir='out')
          labels(i) = append(labels(i),', n: ',string(numel(this.regions_array(1,i).neurons)));
        end
        title(append('Avalanche size distributions for ',this.basename,', state ',this.states(j)) ...
          ,FontSize=17);
        subtitle(append('Δt: ', ...
          string(this.regions_array(1,i).spike_dt)),FontSize=14);
        xlabel('S',FontSize=14);
        ylabel('p(S)',FontSize=14);
        set(gca,TickDir='out')
        legend(labels(i_indeces));
        if opt.save
          print(fig,append(this.results_path,'/size_distr.',string(this.states(j)),'.svg'),'-dsvg')
        end
        if ~opt.show
          close(fig)
        end
      end
    end

    function plotAvalKruskalBar(this,opt)
      arguments
        this (1,1) regions
        opt.states (:,1) string = []
        opt.regions (:,1) double = []
        opt.save (1,1) {mustBeLogical} = false
        opt.show (1,1) {mustBeLogical} = false
      end
      % find requested states and regions
      [j_indeces,i_indeces] = this.getIndeces(opt.states,opt.regions);
      % plot figures
      fig = figure(Name='kruskal',NumberTitle='off',Position=get(0,'Screensize')); hold on
      states_title = "states: ["; % prepare text for plot title
      title_ready = false;
      for i = i_indeces
        subplot(2,ceil(numel(i_indeces)/2),i); hold on
        sizes = [];
        groups = [];
        for j = j_indeces
          s = this.regions_array(j,i).getAvalSizes();
          sizes = [sizes;s];
          groups = [groups;repmat(j,size(s))];
          if ~title_ready
            states_title = append(states_title,string(this.states(j)),', ');
          end
        end
        title_ready = true;
        kruskalbar(sizes,groups,0.05,true);
        title(append(regionID2Acr(this.ids(i))),FontSize=14);
        subtitle(append('n units: ',string(size(this.regions_array(1,i).neurons,1))),FontSize=14);
        ylabel('S',FontSize=14);
        %legend(opt.states);
      end
      sgtitle(append('Avalanche size distributions comparison for ',this.basename,', ',extractBefore( ...
        states_title,strlength(states_title)-1),'], Δt: ', ...
        string(this.regions_array(1,1).spike_dt))); % removing last comma from states_title
      if opt.save
        saveas(fig,append(this.results_path,'/size_comp','.svg'),'svg')
      end
      if ~opt.show
          close(fig)
      end
    end

    function plotAvalancheDistributionsSubplot(this,opt) % SUBPLOT MUST BE IMPROVED
      arguments
        this (1,1) regions
        opt.states (:,1) string = []
        opt.regions (:,1) double = []
        opt.save (1,1) {mustBeLogical} = false
        opt.show (1,1) {mustBeLogical} = false
      end
      % find requested states and regions
      [j_indeces,i_indeces] = this.getIndeces(opt.states,opt.regions);
      % plot figure
      fig = figure(Name='distr',NumberTitle='off',Position=get(0,'Screensize')); hold on
      for i = i_indeces
        ax = subplot(2,ceil(numel(this.ids)/2),i); hold on
        for j = j_indeces
          reg = this.regions_array(j,i);
          histogram(ax,reg.getAvalSizes())
        end
        title(append(getRegionAcr(this.ids(i))));
        subtitle(append('n units: ',string(size(this.regions_array(1,i).neurons,1)),', Δt: ', ...
          string(this.regions_array(1,i).spike_dt)));
        xlabel('S',FontSize=14);
        ylabel('p(S)',FontSize=14);
        legend(opt.states);
      end
      sgtitle(append('Avalanche size distributions for ',this.basename));
      if opt.save
        saveas(fig,append(this.results_path,'/size_distr_subplot','.svg'),'svg')
      end
      if ~opt.show
        close(fig)
      end
    end

    function plotAvalT0(this,opt)
      arguments
        this (1,1) regions
        opt.normalize (1,1) {mustBeLogical} = false
        opt.states (:,1) string = []
        opt.regions (:,1) double = []
        opt.save (1,1) {mustBeLogical} = false
        opt.show (1,1) {mustBeLogical} = false
      end
      % find requested states and regions
      [j_indeces,i_indeces,colors] = this.getIndeces(opt.states,opt.regions);
      % plot figures
      for j = j_indeces
        fig = figure(Name=append('T0_',this.states(j)),NumberTitle='off',Position=get(0,'Screensize'));
        hold on
        labels = regionID2Acr(this.ids);
        for i = i_indeces
          dt = logspace(-3,3,1000);
          T0 = zeros(size(dt));
          for t = 1 : numel(dt)
            region = this.computeAvalanches(spike_dt=dt(t),state=j,region=i);
            T0(t) = min(region.getAvalDurations()) * dt(t);
          end
          plot(dt,T0,Color=colors(1),LineWidth=0.85)
          set(gca,Xscale='log',Yscale='log')
          labels(i) = append(labels(i),', n: ',string(numel(this.regions_array(1,i).neurons)));
        end
        title(append('Minimal avalanche duration for ',this.basename,', state ',this.states(j)) ...
          ,FontSize=17);
        %subtitle(append('Δt: ', ...
        %  string(this.regions_array(1,i).spike_dt)),FontSize=14);
        xlabel('dt',FontSize=14);
        ylabel('T0',FontSize=14);
        legend(labels(i_indeces));
        if opt.save
          % IMPLEMENT SAVING OF MATRIX
          print(fig,append(this.results_path,'/T0.',string(this.states(j)),'.svg'),'-dsvg')
        end
        if ~opt.show
          close(fig)
        end
      end
    end

    % helper methods

    function this = loadAval(this,opt) % NOT ROBUST TO SWITCHING STATE ORDER
      arguments
        this (1,1) regions
        opt.spike_dt (1,1) double {mustBePositive} = 0.02
        opt.threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(opt.threshold,1)} = 0
      end
      % read log file
      extension = append('.',num2str(opt.spike_dt*100000));
      if opt.threshold ~= 0
        extension = append(extension,'.',num2str(opt.threshold*10));
      end
      if this.phase ~= "all"
        extension = append('.',this.phase,extension);
      end
      file_name = append(this.results_path,'/',this.basename,extension,'.aval_log');
      fileID = fopen(file_name);
      if fileID == -1
        err.message = append('Unable to open ',file_name,'.');
        err.identifier = 'loadAval:FileNotFound';
        error(err);
      end
      states = split(string(fgetl(fileID)));
      ids = double(split(string(fgetl(fileID))));
      if isempty(this.ids)
        this.ids = ids;
      end
      n_neurons = double(split(string(fgetl(fileID))));
      n = double(split(string(fgetl(fileID))));
      n = [0;cumsum(n)];
      fclose(fileID);
      % read avalanches
      file_name = append(this.results_path,'/',this.basename,extension,'.aval');
      aval = readmatrix(file_name,FileType='text');
      %
      [i_indeces,j_indeces] = this.getIndeces(states,ids);
      fill = isempty(this.regions_array);
      k = 1;
      for j = j_indeces
        for i = i_indeces % NOT ROBUST TO SWITCHING STATE ORDER
          if fill
            this.regions_array(i,j) = region(this.basename,this.session_path,this.ids(j), ...
              state=this.states(i),n_neurons=n_neurons(k));
          end
          this.regions_array(i,j) = this.regions_array(i,j).setAvalanches(opt.spike_dt,opt.threshold, ...
            aval(n(k)+1:n(k+1),1:2),aval(n(k)+1:n(k+1),3));
          k = k + 1;
        end
      end
    end

    function saveAval(this)
      % pool avalanches 
      n = strings().empty();
      sizes = [];
      durations = [];
      indeces = [];
      n_neurons = [];
      for i = 1 : numel(this.regions_array) % N NEURONI VIENE RIPETUTO INUTILMENTE!!
        s = this.regions_array(i).getAvalSizes();
        n = [n;string(numel(s))]; % WHY string?? CAN DO SAME AS OTHERS
        sizes = [sizes;s];
        %durations = [durations;this.regions_array(i).getAvalDurations()]; DEPRECATED
        indeces = [indeces;this.regions_array(i).getAvalIndeces()];
        n_neurons = [n_neurons;this.regions_array(i).getNNeurons()];
      end
      % create log file with states, regions ids, n of neurons per region, and n of avals
      extension = append('.',num2str(this.regions_array(1).getSpikeDt()*100000));
      if this.regions_array(1).getAvalThreshold() ~= 0
        extension = append(extension,'.',num2str(this.regions_array(1).getAvalThreshold()*10));
      end
      if this.phase ~= "all"
        extension = append('.',this.phase,extension);
      end
      file_name = append(this.results_path,'/',this.basename,extension,'.aval_log');
      if ~isfile(file_name)
        writematrix([],file_name,FileType='text');
      end
      fileID = fopen(file_name,'w');
      fprintf(fileID,append(strjoin(this.states),newline));
      fprintf(fileID,append(strjoin(string(this.ids)),newline));
      fprintf(fileID,append(strjoin(string(n_neurons)),newline));
      fprintf(fileID,append(strjoin(n),newline));
      fclose(fileID);
      % save avalanches
      file_name = append(this.results_path,'/',this.basename,extension,'.aval');
      writematrix([indeces,sizes],file_name,FileType='text');
    end
  end
end
