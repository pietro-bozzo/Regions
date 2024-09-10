function this = computeATMs(this)
% computeATMs Compute Avalanche Transition Matrices for brain network, divided by state

arguments
  this (1,1) regions
end

for i = 1 : numel(this.brain_array)
  this.brain_array(i) = this.brain_array(i).computeATM();
end