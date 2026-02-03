function this = setAvalanches(this,window,threshold,indeces,sizes)
% setAvalanches Set avalanches and relative parameters

arguments
  this (1,1) brain
  window (1,1) double {mustBePositive}
  threshold (1,1) double {mustBeNonnegative}
  indeces (:,2) double
  sizes (:,1) double
end

if any(isnan(indeces))
  [this.IC_window,this.aval_threshold,this.aval_sizes] = deal(NaN);
  this.aval_indeces = [NaN,NaN];
else
  this.IC_window = window;
  this.aval_threshold = threshold;
  this.aval_indeces = indeces;
  this.aval_sizes = sizes;
end