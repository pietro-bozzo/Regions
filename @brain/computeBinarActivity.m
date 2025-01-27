function this = computeBinarActivity(this,time_bin)
% computeBinarActivity Set threshold for avalanche detection and compute binarized z-scored IC activity

arguments
  this (1,1) brain
  time_bin (1,1) double {mustBePositive} % in seconds
end

this.IC_bin_size = time_bin;
this.ICs_binar_activity = getSpikeRaster(this.ICs_activations,bin_size=this.IC_bin_size,relabel=false).';