function [raster,step] = getSpikeRaster(spikes,start,stop,opt)
% getSpikeRaster Get raster matrix of size n_units x n_bins
%
% arguments:
%     spikes     (n_spikes,2) double, each row is [spike_time,unit_id]
%     start      double = 0, x axis will be [start,stop] in s
%     stop       double = 0, default is max spike time
%
% name-value arguments:
%     step       double = 0.05, time bin in s, default is min inter-spike interval
%     relabel    logical = true, if true, relabel units to a {1,...,N} set, preserving unit order in raster, e.g.,
%                  spikes = [1,5;    has units {3,5,9,10} which will be rows {1,2,3,4} in raster
%                            2,3;
%                            3,2;
%                            4,9]
%     sparse     logical = true, if true, output is a sparse matrix, otherwise it's full

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  spikes (:,2) {mustBeNumeric}
  start (1,1) {mustBeNumeric,mustBeNonnegative} = 0
  stop (1,1) {mustBeNumeric,mustBeNonnegative} = spikes(end,1)
  opt.step (1,1) {mustBeNumeric,mustBeNonnegative} = 0
  opt.relabel (1,1) {mustBeLogical} = true
  opt.sparse (1,1) {mustBeLogical} = true
end

if opt.step == 0
  % compute default bin size
  time_steps = spikes(2:end,1)-spikes(1:end-1,1);
  opt.step = min(time_steps(time_steps~=0));
end

if opt.relabel
  [~,~,unit_label] = unique(spikes(:,2));
else
  unit_label = spikes(:,2);
end

% keep samples in [start,stop], discretize time
time_indeces = spikes(spikes(:,1) >= start & spikes(:,1) <= stop,1) - start;
time_indeces = ceil(time_indeces / opt.step);
time_indeces(time_indeces==0) = 1;

% add dummy spike to ensure final columns of zeros in raster (for sparse mdoe)
time_indeces = [time_indeces;ceil((stop-start)/opt.step)];
unit_label = [unit_label;1];

% create raster as sparse matrix
if opt.sparse
  raster = sparse(unit_label,time_indeces,true);
else
  raster_size = [max(unit_label),time_indeces(end)];
  raster = false(raster_size);
  raster(sub2ind(raster_size,unit_label,time_indeces)) = true;
end
% remove dummy spike
raster(1,end) = false;

% return bin size
step = opt.step;