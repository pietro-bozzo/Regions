function this = shuffleICAs(this,opt)
% shuffleICA Shuffle ICs binarized z-scored activity for every state

arguments
  this (1,1) regions
  opt.threshold (1,1) double {mustBeNonnegative} = 0
end

for i = 1 : numel(this.brain_array)
  try
    this.brain_array(i) = this.brain_array(i).shuffleICA(threshold=opt.threshold);
  catch except
    if strcmp(except.identifier,'setAvalThreshold:MissingThreshold')
      error('shuffleICAs:MissingThreshold','Avalanche threshold must be specified when avalanches haven''t been previously computed.');
    else
      rethrow(except)
    end
  end
end