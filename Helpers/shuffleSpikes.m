function shuffled_spikes = shuffleSpikes(spikes,offset)
% shuffleSpikes Shuffle spike list preserving inter-spike intervals distribution for each unit
%
% arguments:
%     spikes        (n_spikes,:) double, each row is [sorted time stamps, optional unit ids]
%     offset = 0    double, reference time, necessary when spikes start at a time ~= 0, e.g., for a portion of a recording
%                   in [1000 s, 3000 s]; must be smaller than first spike time

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  spikes (:,:) {mustBeNumeric}
  offset (1,1) {mustBeNumeric} = 0
end

unique_units = unique(spikes(:,2:size(spikes,2)),'rows');
shuffled_spikes = [];
for unit = unique_units.'
  time_stamps = spikes(all(spikes(:,2:size(spikes,2))==unit.',2),1);
  inter_spike_intervals = diff([offset;time_stamps],1);
  % shuffle inter-spike intervals
  inter_spike_intervals = inter_spike_intervals(randperm(numel(inter_spike_intervals)));
  shuffled_spikes = [shuffled_spikes;offset+cumsum(inter_spike_intervals),repmat(unit.',size(inter_spike_intervals))];
end
shuffled_spikes = sortrows(shuffled_spikes);