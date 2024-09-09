function labeled_spikes = relabelUnits(spikes,rat,opt)
% relabelUnits Get spikes relabeled as [time,brain_region,brain_side,unit_n]
%
% arguments:
% spikes (:,3) double          matrix having columns: sorted time stamps, groups, unit ids
% rat (1,1) {mustBePositive}   rat number
% file_name = ""               file name containing legend between unit ids and anatomical location, default 
%                              is electrAnatPos.txt located in folder Pietro/Data

arguments
  spikes (:,3) double
  rat (1,1) {mustBePositive}
  opt.file_name (1,1) string = ""
end

if strcmp(opt.file_name,"")
  opt.file_name = [getPietroPath,'/Data/electrAnatPos.txt'];
end 

[~,~,unit_label] = unique(spikes(:,2:3),'rows');
legend = readmatrix(opt.file_name);
legend = legend(legend(:,1)==rat,2:end); % keep only rat of interest
if isempty(legend)
  [~,name,ext] = fileparts(opt.file_name);
  error(append('Rat ',string(rat),' not found in ',name,ext))
end
labeled_spikes = spikes;
for i = 1 : length(legend(:,1))
  labeled_spikes(spikes(:,2)==legend(i,1),2) = legend(i,2); % replace group with region
  labeled_spikes(spikes(:,2)==legend(i,1),3) = legend(i,3); % replace unit with brain side
end
labeled_spikes = [labeled_spikes,unit_label]; % add column with labels