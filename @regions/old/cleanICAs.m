function this = cleanICAs(this,opt)
% shuffleICA Clean ICs ...

arguments
  this (1,1) regions
  opt.verbose (1,1) {mustBeLogical} = true
end

for i = 1 : numel(this.brain_array)
  this.brain_array(i) = this.brain_array(i).cleanICA(verbose=opt.verbose);
end