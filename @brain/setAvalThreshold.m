function this = setAvalThreshold(this,threshold)
% computeATM Set threshold for avalanche detection and compute binarized z-scored IC activity

arguments
  this (1,1) brain
  threshold (1,1) double {mustBeNonnegative}
end

% check avalanche threshold
if threshold == 0
  if isempty(this.aval_threshold)
    error('setAvalThreshold:MissingThreshold','Avalanche threshold must be specified when avalanches haven''t been previously computed.');
  end
else
  if ~isempty(this.aval_threshold) && threshold ~= this.aval_threshold
    warning('Avalanche threshold was modified after avalanches were computed.');
  end
  % set new threshold and recompute binarized z-scored IC activity
  this.aval_threshold = threshold;
  this.ICs_binar_activity = abs(zscore(this.ICs_activity)) > this.aval_threshold;
end
if isempty(this.ICs_binar_activity) % if precomputed binarized activty is missing
  this.ICs_binar_activity = abs(zscore(this.ICs_activity)) > this.aval_threshold;
end