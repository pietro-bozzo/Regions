function intervals = getAvalIntervals(this,opt)
% getAvalIntervals Get avalanche start-stop bin indeces SHOULD ERROR IF AVALS NOT COMPUTED

arguments
  this (1,1) brain
  opt.restriction (:,1) double = []
  opt.threshold (1,1) double = 0
end

intervals = (this.aval_indeces-repmat([1,0],size(this.aval_indeces,1),1)) * this.IC_bin_size;
if opt.threshold ~= 0
  intervals = intervals(this.aval_sizes>opt.threshold,:);
end
if ~isempty(opt.restriction)
  intervals = intervals(intervals(:,1)>opt.restriction(1) & intervals(:,2)<opt.restriction(2),:);
end