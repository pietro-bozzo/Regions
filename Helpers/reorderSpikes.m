function spikes = reorderSpikes(spikes,order)
% reorderSpikes Rename units in spike list to give them a new order
%
% arguments:
% spikes (:,2) double                   matrix having sorted time stamps as first column and unit ids as second
% order (:,1) double {mustBeInteger}    ordered list of units

arguments
  spikes (:,2) double
  order (:,1) double {mustBeInteger}
end

if length(unique(order)) ~= length(order)
  err.message = 'Argument order must be not contain duplicates.';
  err.identifier = 'getSpikeRaster:orderFormat';
  error(err);
end
if ~all(ismember(unique(spikes(:,2)),order))
  err.message = 'Argument order contains units not found in spikes.';
  err.identifier = 'getSpikeRaster:orderSpikes';
  error(err);
end
old_spikes = spikes;
for i = 1 : numel(order) % rename units according to order
  spikes(old_spikes(:,2)==order(i),2) = i;
end