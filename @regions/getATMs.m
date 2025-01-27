function ATMs = getATMs(this,delay,opt)
% getATMs Compute Avalanche Transition Matrices for brain network, divided by state

arguments
  this (1,1) regions
  delay (1,1) double {mustBePositive,mustBeInteger} = 1
  opt.restrict (:,2) double {mustBeNonnegative} = []
  opt.shuffle (1,1) {mustBeLogical} = false
  opt.concatenate (1,1) {mustBeLogical} = false
end

ATMs = cell(numel(this.brain_array),1);
for i = 1 : numel(this.brain_array)
  ATMs(i) = this.brain_array(i).getATM(delay,restrict=opt.restrict,shuffle=opt.shuffle,concatenate=opt.concatenate);
end