function [ATMs,ATM_stamps] = getATMs(this,opt)
% computeATMs Get Avalanche Transition Matrices for brain network, divided by state

arguments
  this (1,1) regions
  opt.states (:,1) string = []
end

for i = this.getIndeces(opt.states)
  ATMs{i,1} = this.brain_array(i).ATMs;
  ATM_stamps{i,1} = this.brain_array(i).ATM_stamps;
end