function this = loadSpikes(this,opt)
% loadSpikes Load session spikes
%
% name-value arguments:
%     load = true        logical, if true, load from spikes.mat, bypassing FMAT utilities
%     test = false       logical, if true, load synthetic test spikes
%     shuffle = false    logical, if true, shuffle spikes
%
% output:
%     this               modified regions object

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  opt.load (1,1) {mustBeLogical} = true
  opt.test (1,1) {mustBeLogical} = false
  opt.shuffle (1,1) {mustBeLogical} = false
end

% NEW CODE :D
% load spikes from disk
% SetCurrentSession(fileparts(this.session_path)+"/"+this.basename+".xml",'verbose','off');
% spikes = GetSpikeTimes('output','full');
% spikes = spikes(~ismember(spikes(:,3),[0,1]),:); % remove samples from channels 0 and 1 (artifacts and MUA)

% DEPRECATED
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
  spikes = GetSpikeTimes('output','full');
  spikes = spikes(~ismember(spikes(:,3),[0,1]),:); % remove samples from channels 0 and 1 (artifacts and MUA)
  if opt.load && ~isempty(spikes)
    try
      save(append(this.session_path,'/Data/spikes.mat'),'spikes')
    catch ME
      warning(ME.message)
    end
  end
end

% restrict spikes in required protocol events
if ~this.all_events
  any_event_stamps = sortrows(vertcat(this.event_stamps{:}));
  spikes = Restrict(spikes,any_event_stamps,'shift','off');
end

% if requested, shuffle spikes preserving inter-spike interval for each unit
if opt.shuffle
  spikes = shuffleSpikes(spikes); % IF events ARE NOT CONTIGOUS THIS IS PROBLEMATIC, SHUFFLE SHOULD BE DONE PER event
end
  
% assign unique labels to units
legend_path = fileparts(this.session_path) + "/" + this.basename + ".chanat";
if ~isfile(legend_path)
  legend_path = ""; % default to electrAnatPos.txt file in Regions/Data
end
% relabel spikes as [time,unique_unit_id] REPLACE session_path WITH REAL SESSION xml
[labeled_spikes,region_ids,this.cluster_map,regs] = relabelUnits(fileparts(this.session_path)+"/"+this.basename+".xml",spikes,this.rat,regions=this.ids,anat_file=legend_path);
%valid_ids = region_ids ~= 0; % remove electrode groups having no valid brain side NOT IMPLEMENTED
%unique_ids = unique(region_ids(valid_ids));
if isempty(this.ids) % default when user doesn't request specific regions
  this.ids = regs;
else
  found_ids = intersect(this.ids,regs); % requested regions found in data
  if ~isempty(setdiff(this.ids,found_ids))
    warning("Requested regions "+strjoin(string(setdiff(this.ids,found_ids)),',')+" not found")
  end
  this.ids = found_ids;
end
if isempty(labeled_spikes)
  warning('No spikes to load')
  return
end

% save session duration as sole event time stamps, if no events where required DEPRECATED BUT USEFUL IF loadEvents ERRORS
%if isscalar(this.phases) && this.phases == "all"
%  this.phase_stamps{1} = this.state_stamps{end-1};
%end

% spikes for each region
for i = 1 : numel(this.ids)
  region_spikes = labeled_spikes(region_ids==this.ids(i),:);
  region_units = unique(region_spikes(:,2));
  % add region to array
  this.regions_array(i,1) = region(this.ids(i),region_units,region_spikes);
end