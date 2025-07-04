function [spikes,unique_units] = compactSpikes(spikes,units,opt)
% compactSpikes Relabel units in spike samples to a contigous {1,...,N} set, preserving unit order
%
% arguments:
%     spikes    (n_spikes,2) double, each row is [spike_time,unit_id]
%     units     (n_units,1) double = [], unit ids to have in output (EXPLAIN BETTER)
%
% name-value arguments:
%     clean     logical = false, if true, remove dummy spikes from output (EXPLAIN BETTER)

arguments
  spikes (:,2) double
  units (:,1) double {mustBeInteger,mustBePositive} = []
  opt.clean (1,1) {mustBeLogical} = false
end

if ~isempty(units)
  unique_units = unique(spikes(:,2));

  % find requested units missing from spikes
  units_to_add = setdiff(units,unique_units);
  % add dummy spikes with requested extra units
  spikes = [spikes;zeros(size(units_to_add)),units_to_add];

  % remove unrequested units
  units_to_remove = setdiff(unique_units,units).';
  for i = 1 : numel(units_to_remove)
    spikes = spikes(spikes(:,2) ~= units_to_remove(i),:);
  end
end

% relabel, return unique units as they were before relabeling
[unique_units,~,spikes(:,2)] = unique(spikes(:,2));

% remove dummy spikes
if opt.clean
  spikes = spikes(1:end-numel(units_to_add),:);
end