function [labeled_spikes,region_ids,unit_cluster_map,regs] = relabelUnits(session,spikes,rat,opt)
% relabelUnits Get spikes relabeled as [time,unit_id], sorted by region
%
% arguments:
%     session
%     spikes              (n_spikes,3) double, each row is [spike_time,electrode_group,cluster_id]
%     rat                 double, rat number
%
% name-value arguments:
%     regions             (n_regions,1) double, region ids, assumed to be sorted, default is regions found in anat_file
%     anat_file           string, file containing legend between unit ids and anatomical location, default is electrAnatPos.txt from folder Regions/Data
%     label_file          string, file containing legend between anatomical location and region label TO IMPLEMENT
%
% output:
%     labeled_spikes      (n_spikes,2) double, each row is [spike_time,unit_id]
%     region_ids          (n_spikes,1) double, region id for every spike
%     region_units        {n_regions,1} cell of (n_units,1) double, units of every region NO
%     unit_cluster_map    (n_units,3) double, each row is [electrode_group,cluster_id,channel] for a unit 
%     regs                (n_regions,1) double, region ids

arguments
  session (1,1) string
  spikes (:,3) {mustBeNumeric}
  rat (1,1) {mustBeInteger,mustBePositive}
  opt.regions (:,1) {mustBeInteger,mustBePositive} = []
  opt.anat_file (1,:) char = ''
  opt.label_file (1,1) string = ''
end

% FIRST, LOOK for CE file, if it's there it contains acronyms - electrode groups
% In that case, make up region ids no? And start having ids - labels in R
% default for empty anat_file: CE, then Regions text file

% load file containing anatomical position of electrodes
skip_filter = false; % flag to skip filtering of legend for rat number
if opt.anat_file == ""
  opt.anat_file = [dataPath(),'/electrAnatPos.txt'];
  [~,basename,extension] = fileparts(opt.anat_file);
else
  [~,basename,extension] = fileparts(opt.anat_file);
  rat_n = basename(4:6);
  if strcmp(basename(1:3),'Rat') && all(isstrprop(rat_n,'digit')) && str2double(rat_n) == rat
    skip_filter = true; % skip filtering as legend file is specific to chosen rat
  end
end
legend = readmatrix(opt.anat_file,FileType='text',CommentStyle='%');
if ~skip_filter
  legend = legend(legend(:,1)==rat,2:end); % keep only rat of interest
  if isempty(legend)
    error('Rat '+string(rat)+' not found in '+basename+extension)
  end
end

% try loading .cluloc file containing channel for every cluster
[file_path,basename] = fileparts(session);
cluster_channel_legend = [];
try
  cluster_channel_legend = readmatrix(fullfile(file_path,basename+'.cluloc'),FileType='text',CommentStyle='%');
end

% in case of a .chanat file, use .cluloc file content as legend, replacing channel with brain area and brain side
if extension == ".chanat"
  if isempty(cluster_channel_legend)
    error('relabelUnits:missingLegend','Using ''.chanat'' file, but unable to load ''.cluloc'' file')
  end
  legend(:,2) = legend(:,2) + 1; % remap to 1-N convention
  [~,legend_ind] = ismember(cluster_channel_legend(:,[1,3]),legend(:,1:2),'rows');
  legend = [cluster_channel_legend(:,1:2),legend(legend_ind,end-1:end)];
end

% LOAD DICTIONARY FOR CUSTOM LABELS
%dict = readmatrix(opt.label_file,FileType='text',CommentStyle='%');
% THEN, NO LONGER    10 * legend(i,2) + legend(i,3);     RATHER dict HAS region, side, id TO MATCH IDs

% legend EXPLAIN COLUMN SYNTAX in 2 CASES ... 

% THIS PORTION COULD BE DIRECTLY IN loadSikes, relabelUnits CoUlD BECOME loadLegend
if isempty(opt.regions)
  % default region ids
  opt.regions = unique(10*legend(:,end-1) + legend(:,end));
end
regs = opt.regions;
% reorder spikes according to regions
if size(legend,2) == 3
  egroup_cluster_id = spikes(:,2);
  egroup_cluster_legend = legend(:,1);
else
  % use both electrode group and cluster id to index spikes
  egroup_cluster_id = 10000*spikes(:,2) + spikes(:,3);
  egroup_cluster_legend = 10000*legend(:,1) + legend(:,2);
end
[~,legend_ind] = ismember(egroup_cluster_id,egroup_cluster_legend);
[region_ids,sort_ind] = sort(10*legend(legend_ind,end-1) + legend(legend_ind,end));
sorted_spikes = spikes(sort_ind,:);
% assign unique unit ids
[unit_cluster_map,~,unit_labels] = unique(sorted_spikes(:,2:3),'stable','rows');
labeled_spikes = [sorted_spikes(:,1),unit_labels];
% if clusters were used, add channel information to unit_cluster_map
if ~isempty(cluster_channel_legend)
  [~,legend_ind] = ismember(unit_cluster_map,cluster_channel_legend(:,1:2),'rows');
  if any(legend_ind==0)
    cluster_channel_legend = [cluster_channel_legend;0,0,NaN];
    legend_ind(legend_ind==0) = size(cluster_channel_legend,1);
  end
  unit_cluster_map = [unit_cluster_map,cluster_channel_legend(legend_ind,3)];
else
  unit_cluster_map = [unit_cluster_map,nan(size(unit_cluster_map,1),1)];
end

% if ~all(n_found) OLD WARNING, NOT IMPLMENTED NOW
%   error(append('Some electrodes were not found in ',basename,extension))
% end