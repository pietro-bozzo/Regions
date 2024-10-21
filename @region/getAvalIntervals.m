function intervals = getAvalIntervals(this,opt)
% getAvalIntervals Get start and stop intervals of avalanches computed using region spiking data

arguments
  this (1,1) region
  opt.restriction (:,1) double = []
  opt.threshold (1,1) double {mustBeNonnegative} = 0
end

intervals = (this.aval_indeces-repmat([1,0],numel(this.aval_indeces(:,1)),1)) * this.spike_dt;
if opt.threshold ~= 0
  intervals = intervals(this.aval_sizes>opt.threshold,:);
end
if ~isempty(opt.restriction)
  intervals = intervals(intervals(:,1)>opt.restriction(1) & intervals(:,2)<opt.restriction(2),:);
end