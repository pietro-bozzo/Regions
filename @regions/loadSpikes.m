function this = loadSpikes(this,opt)
% loadSpikes Load session spikes
%
% name-value arguments:
%     load       logical = true, if true, try bypassing FMAT's SetCurrentSession() using (in this order):
%                - CellExplorer's .cell_info-.mat file
%                - Regions' file from <basename>/Regions/Data/spikes.mat
%     save       logical = true, if true, save spikes to <basename>/Regions/Data/spikes.mat when loading via FMAT
%     test       logical = false, if true, load synthetic test spikes
%     legend     string = "", file containing legend between unit ids and anatomical location, default is nonlateral.anatomy from folder Regions/Data
%     shuffle    logical = false, if true, shuffle spikes
%
% output:
%     this       modified regions object

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  opt.load (1,1) {mustBeLogical} = true
  opt.save (1,1) {mustBeLogical} = true
  opt.test (1,1) {mustBeLogical} = false
  opt.legend (1,1) string = ""
  opt.shuffle (1,1) {mustBeLogical} = false
end

% default value
if opt.legend == ""
  %opt.legend = fullfile(this.session_path,this.basename+".chanat"); % NOT IMPLEMENTED FOR NOW
  %if ~isfile(opt.legend)
    opt.legend = fullfile(dataPath(),'nonlateral.anat'); % default to nonlateral.anatomy file in Regions/Data
  %end
end

% load spikes
if opt.test
  spikes = readmatrix(fullfile(this.session_path,this.basename,+".test"),FileType="text");
else

  % load via CellExplorer
  load_mat = opt.load;
  if opt.load
    try
      spikes = GetSpikeTimes('session',fullfile(this.session_path,this.basename+".xml"),'output','full');
      load_mat = false;
    catch
      opt.load = false;
    end
  end

  % load via Regions
  if load_mat
    try
      spikes = load(fullfile(this.session_path,'Regions','Data','spikes.mat'),'spikes');
      spikes = spikes.spikes;
    catch
      load_mat = false
    end
  end

  % load via FMAT
  if ~opt.load && ~load_mat
    SetCurrentSession(fullfile(this.session_path,this.basename+".xml"))
    spikes = GetSpikeTimes('output','full');
    spikes = spikes(~ismember(spikes(:,3),[0,1]),:); % remove samples from channels 0 and 1 (artifacts and MUA)
    % save spikes.mat
    if opt.save
      if ~isfolder(fullfile(this.session_path,'Regions','Data'))
        mkdir(fullfile(this.session_path,'Regions','Data'))
      end
      save(fullfile(this.session_path,'Regions','Data','spikes.mat'),'spikes')
    end
  end

end

% restrict spikes in required protocol events
if ~this.phase.all
  any_event_stamps = sortrows(vertcat(this.phase.times{:}));
  spikes = Restrict(spikes,any_event_stamps,'shift','off');
end

% shuffle spikes preserving inter-spike interval for each unit
if opt.shuffle
  shuffled_spikes = cell(size(this.phase.times));
  for i = 1 : numel(this.phase.times)
    event_spikes = Restrict(spikes,this.phase.times{i});
    shuffled_spikes{i} = shuffleSpikes(event_spikes,this.phase.times{i}(1));
  end
  spikes = vertcat(shuffled_spikes{:});
end

% relabel spikes as [time,unique_unit_id]
[labeled_spikes,region_ids,this.cluster_map,regs] = relabelUnits(fullfile(this.session_path,this.basename+".xml"),spikes,this.rat,opt.legend,regions=this.ids);
if isempty(this.ids) % default when user doesn't request specific regions
  this.ids = regs;
else
  found_ids = intersect(this.ids,regs,'stable'); % requested regions found in data
  if ~isempty(setdiff(this.ids,found_ids))
    warning("Requested regions "+strjoin(string(setdiff(this.ids,found_ids)),',')+" not found")
  end
  this.ids = found_ids;
end
if isempty(labeled_spikes)
  warning('No spikes to load')
  return
end

% use spikes to deduce session duration if loadEvents failed
if isscalar(this.phase.names) && ismissing(this.phase.names)
  this.phase.times{1} = [spikes(1,1),spikes(end,1)];
  this.state.times{end-1} = this.phase.times{1}; % all
  this.state.times{end} = this.state.times{end-1}; % other
  for s = this.state.times(1:end-2).'
    this.state.times{end} = SubtractIntervals(this.state.times{end},s{1});
  end
end

% spikes for each region
for i = 1 : numel(this.ids)
  region_spikes = labeled_spikes(region_ids==this.ids(i),:);
  region_units = unique(region_spikes(:,2));
  % add region to array
  this.regions_array(i,1) = region(this.ids(i),region_units,region_spikes);
end