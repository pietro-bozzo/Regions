function this = cleanICAs(this,opt)
% shuffleICA Clean ICs ...

arguments
  this (1,1) regions
  opt.threshold (1,1) double {mustBeNonnegative} = 0
  opt.verbose (1,1) {mustBeLogical} = true
end

for i = 1 : numel(this.brain_array)
  try
    this.brain_array(i) = this.brain_array(i).cleanICA(threshold=opt.threshold,verbose=opt.verbose);
  catch except
    if strcmp(except.identifier,'setAvalThreshold:MissingThreshold')
      error('shuffleICAs:MissingThreshold','Avalanche threshold must be specified when avalanches haven''t been previously computed.');
    else
      rethrow(except)
    end
  end
end