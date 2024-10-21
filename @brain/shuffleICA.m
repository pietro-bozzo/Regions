function this = shuffleICA(this,opt)
% shuffleICA Shuffle ICs binarized z-scored activity

arguments
  this (1,1) brain
  opt.threshold (1,1) double {mustBeNonnegative} = 0
end

this = this.setAvalThreshold(opt.threshold);
% shuffle activity
this.ICs_binar_activity = shuffleSpikeMatrix(this.ICs_binar_activity.').';