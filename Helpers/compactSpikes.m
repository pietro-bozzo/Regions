function [spikes,unique_units] = compactSpikes(spikes,units)
% compactSpikes Summary of this function goes here

arguments
  spikes (:,2) double
  units (:,1) double {mustBeInteger,mustBePositive} = []
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

% relabel units to a contigous {1,...,N} set, preserving unit order
% return unique units as they were before relabeling
[unique_units,~,spikes(:,2)] = unique(spikes(:,2));

% remove dummy spikes IF DUMMY ARE LAST IN NUMBER, THEY ARE LOST, MAYBE DON'T REMOVE?
%spikes = spikes(1:end-numel(units_to_add),:);