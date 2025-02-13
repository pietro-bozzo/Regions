function this = loadSpikes(this,opt)
% loadSpikes Load Session .xml file and construct the regions_array using spikes
arguments
  this (1,1) regions
  opt.load (1,1) {mustBeLogical} = true     % load from .mat, bypassing FMAT
  opt.test (1,1) {mustBeLogical} = false    % load synthetic test spikes
  opt.shuffle (1,1) {mustBeLogical} = false
end
  
% load spikes from disk
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
  
% assign unique labels to units
legend_path = append(fileparts(this.session_path),'/',this.basename,'.cluloc');
if ~isfile(legend_path)
  legend_path = ""; % default to electrAnatPos.txt file
end
[labeled_spikes,reg_ids] = relabelUnits(spikes,this.rat,file_name=legend_path); % relabel spikes as [time,unique_unit_n]
valid_ids = reg_ids ~= 0; % remove bundles having no valid brain side
unique_ids = unique(reg_ids(valid_ids));
if isempty(this.ids) % default when user doesn't request specific regions
  this.ids = unique_ids;
else
  found_ids = intersect(this.ids,unique_ids); % requested regions found in data
  if ~isempty(setdiff(this.ids,found_ids))
    warning(append('Requested regions ',strjoin(string(setdiff(this.ids,found_ids)),','),' not found.'))
  end
end
n_units_cum = 0;
brain_neurons = []; % TO IMPLEMENT
% get spikes for each region
for i = 1 : numel(this.ids)
  region_spikes = labeled_spikes(reg_ids==this.ids(i),:);
  % relabel units to a contigous {1,...,N} set, preserving unit order
  [region_spikes,region_neurons] = compactSpikes(region_spikes);
  % give units a unique id
  region_neurons = (1 : numel(region_neurons)).' + n_units_cum;
  region_spikes(:,2) = region_spikes(:,2) + n_units_cum;
  n_units_cum = n_units_cum + numel(region_neurons);
  % add region
  this.regions_array(i,1) = region(this.ids(i),region_neurons,region_spikes);
  %brain_neurons = [brain_neurons;region_neurons]; TO IMPLEMENT  
end