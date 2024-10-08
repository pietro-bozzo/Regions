function this = loadSpikes(this,opt)
  % loadSpikes Load Session .xml file and construct the regions_array using spikes
  arguments
    this (1,1) regions
    opt.load (1,1) {mustBeLogical} = true    % load from .mat, bypassing FMAT
    opt.test (1,1) {mustBeLogical} = false    % load synthetic test spikes
    opt.shuffle (1,1) {mustBeLogical} = false
  end
  
  loadFMAT = ~opt.load; % flag to load spikes using slower FMAT utility
  if opt.load
    if ~isfolder(append(this.session_path,'/Data'))
      mkdir(append(this.session_path,'/Data'))
      loadFMAT = true;
    elseif ~isfile(append(this.session_path,'/Data/spikes.mat'))
      loadFMAT = true;
    else
      load(append(this.session_path,'/Data/spikes.mat'),'spikes');
    end
  elseif opt.test
    spikes = readmatrix(append(fileparts(this.session_path),'/',this.basename,'.test'),FileType="text");
  end
  if loadFMAT && ~opt.test
    % load .xml file
    SetCurrentSession([char(fileparts(this.session_path)),'/',this.basename,'.xml'],'verbose','off');
    % load spikes
    spikes = GetSpikeTimes([GetGroups,repmat(-1,length(GetGroups),1)],'output','full');
    if opt.load
      save(append(this.session_path,'/Data/spikes.mat'),'spikes')
    end
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
  if opt.shuffle
    spikes = shuffleSpikes(spikes); % IF events ARE NOT CONTIGOUS THIS IS PROBLEMATIC, AN arg FOR shuffleSpikes SHOULD EXIST
  end
  % create regions array
  labeled_spikes = relabelUnits(spikes,this.rat); % relabel as [time,brain_region,brain_side,unit_n]
  reg_ids = 10*labeled_spikes(:,2) + labeled_spikes(:,3); % assign id to each brain region
  valid_ids = reg_ids ~= 0; % remove bundles having no valid brain side
  unique_ids = unique(reg_ids(valid_ids));
  if isempty(this.ids) % default when user doesn't request specific regions
    this.ids = [unique_ids;0];
  else
    found_ids = intersect(this.ids,[unique_ids;0]); % requested regions found in data
    if ~isempty(setdiff(this.ids,found_ids))
      warning(append('Requested regions ',strjoin(string(setdiff(this.ids,found_ids)),','),' not found.'))
    end
  end
  brain_neurons = [];
  % get spikes for each region
  for i = 1 : numel(this.ids(this.ids~=0))
    region_spikes = labeled_spikes(reg_ids==this.ids(i),[1,4]);
    region_neurons = unique(region_spikes(:,2));
    brain_neurons = [brain_neurons;region_neurons];
    for j = 1 : numel(this.states)
      if strcmp(this.states(j),"all") % if no specific brain state is requested
        this.regions_array(j,i) = region(this.basename,this.session_path,this.ids(i),region_neurons,region_spikes);
      else % get spikes for specific brain state HERE Restrict IS USED MULTIPLE TIMES ON SAME DATA: SHOULD IMPLEMENT A f THAT DOES IT ONCE WITH MANY state_stamps AND MAYBE DO BEFORE FINDING REGION
        this.regions_array(j,i) = region(this.basename,this.session_path,this.ids(i),region_neurons,Restrict(region_spikes,this.state_stamps{j},'shift','off'),state=this.states(j));
      end
    end      
  end
  i = size(this.regions_array,2); % needed in case this.ids == [0]
  if this.ids(end) == 0 % add a region containing spikes of whole brain
    for j = 1 : numel(this.states)
      if strcmp(this.states(j),"all")
        this.regions_array(j,i+1) = region(this.basename,this.session_path,0,brain_neurons,labeled_spikes(valid_ids,[1,4]));
      else
        this.regions_array(j,i+1) = region(this.basename,this.session_path,0,brain_neurons,Restrict(labeled_spikes(valid_ids,[1,4]),this.state_stamps{j},'shift','off'),state=this.states(j));
      end
    end
  end
end