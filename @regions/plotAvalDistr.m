function fig = plotAvalDistr(this,opt)
% plotFiringRates Plot avalanche size distributions per region
%
% name-value arguments:
%     state      string = 'all', behavioral state
%     regions    (n_regs,1) double = [], brain regions, defaults to all regions
%
% output:
%     fig        figure

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  opt.state (1,1) string = 'all'
  opt.regions (:,1) double = []
end

% make figure
fig = figure(Name='distr',NumberTitle='off',Position=get(0,'Screensize')); hold on
title("Avalanche size distributions for "+this.printBasename()+', w: '+num2str(this.aval_window)+', s: '+num2str(this.aval_smooth)+', t: '+num2str(this.aval_threshold));

% find requested states and regions
[~,r_indeces,opt.state,opt.regions] = this.indeces(opt.state,opt.regions);

% compute average firing rate per region
average_fr = zeros(size(opt.regions));
max_duration = 0;
for r = 1 : numel(r_indeces)
  spikes = this.spikes('all',opt.regions(r));
  average_fr(r) = size(spikes,1); % number of spikes
  max_duration = max(max_duration,spikes(end,1)-spikes(1,1));
end
average_fr = average_fr / max_duration; % normalize by recording duration

% color code by average firing rate to show that it organizes distributions
color_coding = average_fr / max(average_fr);

% get sizes
sizes = {};
labels = string.empty;
for reg = opt.regions.'
  sizes{end+1,1} = this.avalSizes(opt.state,reg);
  labels(end+1,1) = regionID2Acr(reg) + ', n: ' + num2str(this.nNeurons(reg));
end

% plot distributions
plotAvalDistrOnAxis(gca,sizes{:},labels=labels,colors=myColors(color_coding,'rainbow'));