function this = loadSpikes(this,opt)
  % loadSpikes Load Session .xml file and construct the regions_array using spikes
  arguments
    this (1,1) regions
    opt.test (1,1) {mustBeLogical} = false
  end
  
  if opt.test
    spikes = readmatrix(append(fileparts(this.session_path),'/',this.basename,'.test'),FileType="text");
  else
    % load .xml file
    SetCurrentSession([char(fileparts(this.session_path)),'/',this.basename,'.xml'],'verbose','off');
    % load spikes
    spikes = GetSpikeTimes([GetGroups,repmat(-1,length(GetGroups),1)],'output','full');
  end
  % load behavioral time stamps
  restrict_intervals = cell(size(this.states));
  this.state_timestamp = restrict_intervals;
  events_path = append(fileparts(this.session_path),'/events/');
  if isfolder(append(events_path,'2021'))
    events_path = append(events_path,'2021/');
  end
  awake = 0;
  for i = 1 : numel(this.states)
    if this.states(i) == "awake"
      restrict_intervals{i} = [0,spikes(end,1)];
      awake = i;
    elseif this.states(i) ~= "all"
      % IMPLEMENT ALLOWED STATES LIST, TAHT FORCES ORDER OF STATES
      % ALWAYS, NO MORE ORDER PROBLEM!
      restrict_intervals{i} = readmatrix(append(events_path,this.basename,'.',this.states(i)), ...
        FileType='text');
    end
  end
  if awake ~= 0
    for i = 1 : numel(this.states)
      if i ~= awake && this.states(i) ~= "all"
        restrict_intervals{awake} = SubtractIntervals(restrict_intervals{awake},restrict_intervals{i});
      end
    end
  end
  % load protocol phases and filter spikes
  phase_stamps = [];
  if this.phase ~= "all"
    events = LoadEvents(append(fileparts(this.session_path),'/',this.basename,'.cat.evt'));
    for i = 1 : numel(events.description)
      if events.description{i}(end-strlength(this.phase)+1:end) == this.phase
        phase_stamps = [phase_stamps;events.time(i)];
      end
    end
    if numel(phase_stamps) < 2
      err.message = append('Unable to find two time stamps for ',this.phase,'.');
      err.identifier = 'loadSpikes:MissingPhaseStamps';
      error(err);
    elseif numel(phase_stamps) > 2
      fprintf(1,append('Warning: more than two time stamps found for ',this.phase,'.\n'))
    end
    spikes = spikes(spikes(:,1) > phase_stamps(1) & spikes(:,1) < phase_stamps(2),:);
  end
  % create regions array
  labeled_spikes = relabelUnits(spikes,this.rat); % relabel as [time,brain_region,brain_side,unit_n]
  reg_ids = 10*labeled_spikes(:,2) + labeled_spikes(:,3); % assign id to each brain region
  valid_ids = reg_ids ~= 0; % remove bundles having no valid brain side
  unique_ids = unique(reg_ids(valid_ids));
  if isempty(this.ids)
    this.ids = [unique(reg_ids(valid_ids));0];
    found_ids = this.ids;
  else
    found_ids = intersect([unique(reg_ids(valid_ids));0],this.ids);
    if isempty(found_ids)
      warning('Requested regions not found.');
    elseif found_ids(1) == 0
      found_ids = [found_ids(2:end);0];
    end
    % SHOULD ADD warning: these are not found FOR THE OUTPUT OF setdiff(unique(reg_ids(valid_ids)),this.ids)
  end
  brain_neurons = [];
  k = 1;
  for i = 1 : numel(unique_ids) % get spikes for brain regions
    region_spikes = labeled_spikes(reg_ids==unique_ids(i),[1,4]);
    region_neurons = unique(region_spikes(:,2));
    brain_neurons = [brain_neurons;region_neurons];
    if unique_ids(i) == found_ids(k)
      for j = 1 : numel(this.states)
        if strcmp(this.states(j),"all")
          this.regions_array(j,k) = region(this.basename,this.session_path,found_ids(k), ...
            region_neurons,region_spikes);
        else % get spikes for specific brain states
          this.regions_array(j,k) = region(this.basename,this.session_path,found_ids(k), ...
            region_neurons,Restrict(region_spikes,restrict_intervals{j},'shift','off'),state= ...
            this.states(j));
        end
      end
      k = k + 1;
    end
  end
  i = size(this.regions_array,2); % needed in case found_ids == [0]
  if found_ids(end) == 0
    for j = 1 : numel(this.states) % get spikes for whole brain
      if strcmp(this.states(j),"all")
        this.regions_array(j,i+1) = region(this.basename,this.session_path,0, ...
          brain_neurons,labeled_spikes(valid_ids,[1,4]));
      else
        this.regions_array(j,i+1) = region(this.basename,this.session_path,0, ...
          brain_neurons,Restrict(labeled_spikes(valid_ids,[1,4]),restrict_intervals{j}, ...
          'shift','off'),state=this.states(j));
      end
    end
  end
end