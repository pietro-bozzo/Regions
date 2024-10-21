function this = computeATMs(this,opt)
% computeATMs Compute Avalanche Transition Matrices for brain network, divided by state, and store them

arguments
  this (1,1) regions
  opt.threshold (1,1) double {mustBeNonnegative} = 0
  opt.restrict (:,2) double {mustBeNonnegative} = []
  opt.shuffle (1,1) {mustBeLogical} = false
end

for i = 1 : numel(this.brain_array)
  try
    this.brain_array(i) = this.brain_array(i).computeATM(threshold=opt.threshold,restrict=opt.restrict,shuffle=opt.shuffle);
  catch except
    if strcmp(except.identifier,'setAvalThreshold:MissingThreshold')
      error('computeATMs:MissingThreshold','Avalanche threshold must be specified when avalanches haven''t been previously computed.');
    else
      rethrow(except)
    end
  end
end