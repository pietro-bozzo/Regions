function this = shuffleSpikes(this,gap)
% shuffleSpikes Shuffle session spikes per session event, preserving inter-spike intervals distribution for each unit
%
% arguments:
%     gap     maximum gap allowed between spikes, farther spikes are shuffled in separated blocks
%
% output:
%     this    modified regions object

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  gap (1,1) {mustBeNumeric,mustBePositive} = 0
end

for i = 1 : numel(this.ids)
  % region spikes
  spikes = this.regions_array(i).spikes;
  shuffled_spikes = {};
  for j = 1 : numel(this.event_stamps)
    % spikes in an event
    event_spikes = Restrict(spikes,this.event_stamps{j});
    if gap ~= 0
      % separate spikes in blocks which are farther than gap
      isi = diff(event_spikes(:,1));
      int_ind = find(isi > gap);
      int_ind = [[1;int_ind+1],[int_ind;size(event_spikes,1)]];
      for ind = int_ind.'
        shuffled_spikes{end+1} = shuffleSpikes(event_spikes(ind(1):ind(2),:),event_spikes(ind(1),1));
      end
    else
      shuffled_spikes{end+1} = shuffleSpikes(event_spikes,this.event_stamps{j}(1));
    end
  end
  this.regions_array(i) = this.regions_array(i).setSpikes(vertcat(shuffled_spikes{:}));
end