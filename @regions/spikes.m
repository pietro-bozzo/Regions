function spikes = spikes(this,state,regs,opt)
% spikes Get spike samples
%
% arguments:
%     state       string = 'all', behavioral state
%     regs        (n_regs,1) double = [], brain regions, default is all regions
%
% name-value arguments:
%     restrict    (n_intervals,2) double = [], each row is a [start,stop] interval, discard spikes falling
%                 outside one of these intervals
%
% output:
%     spikes      (n_spikes,2) double, spike samples, each row is [spike_time,unit_id]

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  state (1,1) string = "all"
  regs (:,1) double = [] % IMPLEMENT POSSIBILITY TO GIVE ACR?
  opt.restrict (:,2) double = []
end

if ~this.hasSpikes()
  error('spikes:MissingSpikes','Spikes have not been loaded')
end

% find requested state and regions
try
  [s_index,r_indeces] = this.indeces(state,regs);
catch ME
  throw(ME)
end

% get activations of requested reagions
spikes = [];
for r = r_indeces
  spikes = [spikes;this.regions_array(r).spikes];
end

% sort by time
spikes = sortrows(spikes);

% restrict
if ~isempty(opt.restrict)
  spikes = Restrict(spikes,opt.restrict,'shift','off');
end

% filter by state
if state ~= "all"
  spikes = Restrict(spikes,this.state_stamps{s_index},'shift','off');
end