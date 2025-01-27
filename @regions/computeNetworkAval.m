function this = computeNetworkAval(this)
% computeNetworkAval Compute avalanches using binarized IC activity from each region

arguments
  this (1,1) regions
end

for i = 1 : numel(this.brain_array)
  this.brain_array(i) = this.brain_array(i).computeAvalanches();
end