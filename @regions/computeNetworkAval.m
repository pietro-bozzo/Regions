function this = computeNetworkAval(this,opt)
% computeNetworkAval Compute avalanches using IC activity from each region

arguments
  this (1,1) regions
  opt.threshold (1,1) double {mustBeNonnegative} = 0
  opt.save (1,1) {mustBeLogical} = false % SAVE avals, TO IMPLEMENT (MAYBE, IF SLOW)
end

for i = 1 : numel(this.brain_array)
  this.brain_array(i) = this.brain_array(i).computeAvalanches(threshold=opt.threshold);
end