function durations = getAvalDurations(this,opt)
% getAvalDurations Get avalanche durations

arguments
  this (1,1) brain
  opt.full (1,1) {mustBeLogical} = false % if true, get also zeros for all times without aval
end

if opt.full
  durations = zeros(this.aval_indeces(end),1);
  durations(this.aval_indeces(:,1)) = this.aval_indeces(:,2) - this.aval_indeces(:,1) + 1;
else
  durations = this.aval_indeces(:,2) - this.aval_indeces(:,1) + 1;
end