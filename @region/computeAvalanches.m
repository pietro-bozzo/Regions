function this = computeAvalanches(this,opt)
% computeAvalanches Compute avalanches using region spiking data

arguments
  this (1,1) region
  opt.spike_dt (1,1) double {mustBePositive} = 0.02
  opt.threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(opt.threshold,1)} = 0
end

this.spike_dt = opt.spike_dt;
this.aval_threshold = opt.threshold;
[this.aval_sizes,this.aval_profile,this.aval_indeces,~,this.aval_timeDependendentSize] = getAvalanchesFromList(this.spikes,this.spike_dt,threshold=opt.threshold);