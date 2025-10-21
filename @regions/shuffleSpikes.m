function this = shuffleSpikes(this)
% shuffleSpikes Shuffle session spikes per event, preserving inter-spike intervals distribution for each unit
%
% output:
%     this               modified regions object

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

for i = 1 : numel(this.ids)
  spikes = this.regions_array(i).spikes;
  shuffled_spikes = [];
  for j = 1 : numel(this.event_stamps)
    event_spikes = Restrict(spikes,this.event_stamps{j});
    shuffled_spikes = [shuffled_spikes;shuffleSpikes(event_spikes,this.event_stamps{j}(1))];
  end
  this.regions_array(i) = this.regions_array(i).setSpikes(shuffled_spikes);
end