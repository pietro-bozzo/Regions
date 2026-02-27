function [labeled_spikes,region_ids,unit_cluster_map,regs] = relabelUnits(session,spikes,rat,anat_file,opt)
% relabelUnits Get spikes relabeled as [time,unit_id], sorted by region
%
% arguments:
%     session             string, path to session .xml file
%     spikes              (n_spikes,3) double, each row is [spike_time,electrode_group,cluster_id]
%     rat                 double, rat number
%     anat_file           string, file containing legend between unit ids and anatomical location
%
% name-value arguments:
%     regions             (n_regions,1) string, region ids, assumed to be sorted, default is regions found in anat_file
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
  anat_file (1,:) char = ''
  opt.regions (:,1) string = []
  opt.label_file (1,1) string = ''
end

% load file containing anatomical position of electrodes
[~,basename,extension] = fileparts(anat_file);

% load legend, removing comments
legend = cellfun(@(y) y{1},cellfun(@(x) strsplit(x,'%'),readlines(anat_file),'UniformOutput',false),'UniformOutput',false);
legend = legend(~cellfun(@isempty,legend));
legend = cellfun(@(x) textscan(x,'%f,%f,%s'),legend,'UniformOutput',false);
legend_rat = cellfun(@(x) x{1},legend);
legend_electrode = cellfun(@(x) x{2},legend);
legend_label = string(cellfun(@(x) x{3},legend));

% flag to skip filtering of legend for rat number OLD
%legend = readmatrix(anat_file,FileType='text',CommentStyle='%');
%rat_n = basename(4:6);
%skip_filter = strcmp(basename(1:3),'Rat') && all(isstrprop(rat_n,'digit')) && str2double(rat_n) == rat;

% keep only rat of interest
is_ok = legend_rat==rat;
if ~any(is_ok)
  error("Rat "+string(rat)+" not found in "+basename+extension)
end
legend_electrode = legend_electrode(is_ok); legend_label = legend_label(is_ok);

% try loading .cluloc file containing channel for every cluster
[file_path,basename] = fileparts(session);
try
  cluster_channel_legend = readmatrix(fullfile(file_path,basename+'.cluloc'),FileType='text',CommentStyle='%');
catch
  cluster_channel_legend = [];
end

% in case of a .chanat file, use .cluloc file content as legend, replacing channel with brain area and brain side NOT IMPLEMENTED
if extension == ".chanat"
  if isempty(cluster_channel_legend)
    error('relabelUnits:missingLegend','Using ''.chanat'' file, but unable to load ''.cluloc'' file')
  end
  legend(:,2) = legend(:,2) + 1; % remap to 1-N convention
  [~,legend_ind] = ismember(cluster_channel_legend(:,[1,3]),legend(:,1:2),'rows');
  legend = [cluster_channel_legend(:,1:2),legend(legend_ind,end-1:end)];
end

% legend EXPLAIN COLUMN SYNTAX in 2 CASES ... 

if isempty(opt.regions)
  % default region ids
  opt.regions = unique(legend_label);
end
regs = opt.regions;
[~,legend_order] = ismember(legend_label,regs);
% reorder spikes according to regions
if size(legend,2) == 1 % NOT VERY USEFUL
  egroup_cluster_id = spikes(:,2);
  egroup_cluster_legend = legend_electrode;
else
  % use both electrode group and cluster id to index spikes NOT IMPLEMENTED
  egroup_cluster_id = 10000*spikes(:,2) + spikes(:,3);
  egroup_cluster_legend = 10000*legend(:,1) + legend(:,2);
end
% assign each spike to a region
[~,legend_ind] = ismember(egroup_cluster_id,egroup_cluster_legend);
if ~all(legend_ind)
  error('relabelunits:missingElectrode',"Some electrode groups where not found in "+anat_file)
end
labels = legend_label(legend_ind);
% divide spikes per region and sort according to 'regs'
sort_ind = legend_order(legend_ind);
[~,sort_ind] = sort(sort_ind);
region_ids = labels(sort_ind);
sorted_spikes = spikes(sort_ind,:);
% assign unique unit ids
[unit_cluster_map,~,unit_labels] = unique(sorted_spikes(:,2:3),'stable','rows');
labeled_spikes = [sorted_spikes(:,1),unit_labels];
% if clusters were used, add channel information to unit_cluster_map NOT IMPLEMENTED
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