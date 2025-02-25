function TMs = getTMs(this,window,lag,opt)
% getATMs Compute Transition Matrices for brain network, divided by state

arguments
  this (1,1) regions
  window (1,1) double {mustBePositive}
  lag (1,1) double {mustBeNonnegative} = 0
  opt.restrict (:,2) double {mustBeNonnegative} = []
  opt.shuffle (1,1) {mustBeLogical} = false
end

TMs = cell(numel(this.brain_array),1);
for i = 1 : numel(this.brain_array)
  TMs{i} = this.brain_array(i).getTM(window,lag,restrict=opt.restrict,shuffle=opt.shuffle);
end