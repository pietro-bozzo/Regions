function this = setAvalanches(this,sizes,intervals)
% setAvalanches Set avalanche members of the region object

arguments
  this (1,1) region
  sizes (:,1) double
  intervals (:,2) double
end

if numel(sizes) ~= size(intervals,1)
  error('setAvalanches:intervalsSize','Length of sizes must correspond to first dimension of intervals.')
end

this.aval_sizes = sizes;
this.aval_intervals = intervals;