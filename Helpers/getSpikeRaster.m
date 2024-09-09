function [raster,bin_size] = getSpikeRaster(spikes,opt)
% getSpikeRaster Get raster matrix of size n_units x n_bins
%
% arguments:
% spikes (:,2) double                      matrix having sorted time stamps as first column and unit ids as second
% bin_size (1,1) double = 0                size of time bins in the raster, default is min inter-spike interval
% end_time (1,1) double = spikes(end,1)    sup of raster time interval such that it is [0,end_time]

arguments
  spikes (:,2) double
  opt.start_time (1,1) double {mustBeNonnegative} = 0
  opt.bin_size (1,1) double {mustBeNonnegative} = 0
  opt.end_time (1,1) double {mustBeNonnegative} = spikes(end,1)
end

if opt.bin_size == 0
    % compute default bin size
    time_steps = spikes(2:end,1)-spikes(1:end-1,1);
    opt.bin_size = min(time_steps(time_steps~=0));
end
if opt.end_time == 0
  % set default end time
  opt.end_time = spikes(end,1);
end

% relabel units to a {1,...,N} set; unit order is preserved in raster,
% e.g., spikes = [1,5;    has units {3,5,9,10} which will be rows {1,2,3,4} in raster
%                 2,3;
%                 3,10;
%                 4,9]
[~,~,unit_label] = unique(spikes(:,2));
% discretize time
edges = opt.start_time : opt.bin_size : opt.end_time+opt.bin_size;
time_indeces = discretize(spikes(:,1),edges);
valid_indeces = time_indeces(~isnan(time_indeces)); % remove NaNs as they are elments ouside end_time
if ~isempty(valid_indeces) && valid_indeces(end) ~= length(edges)-1 % if there are trailing zeros in time
  % add dummy spike to ensure final columns of zeros in raster
  time_indeces = [time_indeces;length(edges)-1];
  unit_label = [unit_label;1];
end
% create raster as sparse matrix
raster = sparse(unit_label(~isnan(time_indeces)),time_indeces(~isnan(time_indeces)),true);
if ~isempty(valid_indeces) && valid_indeces(end) ~= length(edges)-1 % remove dummy spike
  raster(1,end) = 0;
end
% return used bin size
bin_size = opt.bin_size;