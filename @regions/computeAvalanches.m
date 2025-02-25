function this = computeAvalanches(this,window,smooth,threshold)
% computeAvalanches Compute avalanches per region from spiking data
%
% arguments:
%     window       double = 0.01, time bin (s) for avalanche computation
%     smooth       double = 2, gaussian kernel std in number of samples
%     threshold    double = 30, percentile of region firing rate for avalanche computation

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  window (1,1) double {mustBePositive} = 0.01 % i.e., 10 ms
  smooth (1,1) double {mustBeNonnegative} = 2
  threshold (1,1) double {mustBeNonnegative} = 30
end

for i = 1 : numel(this.ids)
  % detect avalanches on population firing rate
  [FR,time] = this.firingRate('all',this.ids(i),window=window,smooth=smooth);
  [sizes,intervals] = avalanchesFromProfile(FR,time(2)-time(1),threshold);
  % save results in region object
  this.regions_array(i) = this.regions_array(i).setAvalanches(sizes,intervals);
end

% store analysis parameters
this.aval_window = window;
this.aval_smooth = smooth;
this.aval_threshold = threshold;