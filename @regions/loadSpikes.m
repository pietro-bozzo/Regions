function this = loadSpikes(this,opt)
  % loadSpikes Load Session .xml file and construct the regions_array using spikes
  arguments
    this (1,1) regions
    opt.shuffle (1,1) {mustBeLogical} = false
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
  % filter spikes for protocol phase
  if numel(this.phase_stamps) > 1 || this.phases ~= "all"
    restrict = [];
    for stamps = this.phase_stamps.'
      restrict = [restrict;stamps{1}];
    end
    spikes = Restrict(spikes,restrict,'shift','off');
  end
  % if requested, shuffle spikes preserving inter-spike interval for each unit
  % IF events ARE NOT CONTIGOUS THIS IS PROBLEMATIC, AN arg FOR shuffleSpikes SHOULD EXIST
  if opt.shuffle
    spikes = shuffleSpikes(spikes);
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
            region_neurons,Restrict(region_spikes,this.state_stamps{j},'shift','off'),state= ...
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
          brain_neurons,Restrict(labeled_spikes(valid_ids,[1,4]),this.state_stamps{j}, ...
          'shift','off'),state=this.states(j));
      end
    end
  end
end