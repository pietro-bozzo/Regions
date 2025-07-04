function [labeled_spikes,region_ids] = relabelUnits(spikes,rat,opt)
% relabelUnits Get spikes relabeled as [time,unit_id] as well as region_id for every spike
%
% arguments:
%     spikes        (n_spikes,3) double, each column is [spike_time,group,cluster_id]
%     rat           double, rat number
%
% name-value arguments:
%     anat_file     string, file containing legend between unit ids and anatomical location, default is electrAnatPos.txt located in folder Regions/Data
%     label_file    string, file containing legend between anatomical location and region label TO IMPLEMENT
%
% output:
%     labeled_spikes    (n_spikes,2) double, each column is [spike_time,unit_id]
%     region_ids        (n_spikes,1) double, region id of every spike

arguments
  spikes (:,3) {mustBeNumeric}
  rat (1,1) {mustBeInteger,mustBePositive}
  opt.anat_file (1,:) char = ''
  opt.label_file (1,1) string = ''
end

skip_filter = false; % flag to skip filtering of legend for rat number
if strcmp(opt.anat_file,"")
  opt.anat_file = [dataPath(),'/electrAnatPos.txt'];
  [file_path,basename,extension] = fileparts(opt.anat_file);
else
  [file_path,basename,extension] = fileparts(opt.anat_file);
  rat_n = basename(4:6);
  if strcmp(basename(1:3),'Rat') && all(isstrprop(rat_n,'digit')) && str2double(rat_n) == rat
    skip_filter = true; % skip filtering as legend file is specific to chosen rat
  end
end

% load file containing anatomical position of electrodes
legend = readmatrix(opt.anat_file,FileType='text',CommentStyle='%');
if ~skip_filter
  legend = legend(legend(:,1)==rat,2:end); % keep only rat of interest
  if isempty(legend)
    error('Rat '+string(rat)+' not found in '+basename+extension)
  end
end

% in case of a .cluloc file, adjust legend replacing channels with brain area and brain side
if extension == ".cluloc"
  % look for .chanat file in session folder
  split = strsplit(file_path,basename);
  try
    unit_channel_legend = readmatrix([split{1},basename,'/',basename,'.chanat'],FileType='text');
  catch except
    if strcmp(except.identifier,'MATLAB:textio:textio:FileNotFound')
      error('relabelUnits:missingLegend','Unable to load .chanat file.')
    else
      throw(except)
    end
  end
  unit_channel_legend(:,2) = unit_channel_legend(:,2) + 1;
  % replace channel with [brain area, brain side]
  for i = 1 : size(unit_channel_legend,1)
    ind = legend(:,1) == unit_channel_legend(i,1) & legend(:,3) == unit_channel_legend(i,2);
    legend(ind,3) = unit_channel_legend(i,3);
    legend(ind,4) = unit_channel_legend(i,4);
  end
  % make unique electrode_cluster indeces, the chosen syntax can handle up to 1000 electrodes
  spikes(:,2) = 1000 * spikes(:,3) + spikes(:,2);
  legend(:,1) = 1000 * legend(:,2) + legend(:,1);
  legend(:,2:3) = legend(:,3:4);
end

% relable units
[~,~,unit_label] = unique(spikes(:,2:3),'rows'); % get unique unit id
labeled_spikes = [spikes(:,1),unit_label];
region_ids = zeros(size(spikes(:,1)));
n_found = false(size(spikes(:,1)));

% LOAD DICTIONARY FOR CUSTOM LABELS
%dict = readmatrix(opt.label_file,FileType='text',CommentStyle='%');
% THEN, NO LONGER    10 * legend(i,2) + legend(i,3);     RATHER dict HAS region, side, id TO MATCH IDs

for i = 1 : size(legend,1)
  ind = spikes(:,2) == legend(i,1);
  region_ids(ind) = 10 * legend(i,2) + legend(i,3); % replace group with region
  n_found(ind) = true; % count total number of found elements in region_ids
end
if ~all(n_found)
  error(append('Some electrodes were not found in ',basename,extension))
end