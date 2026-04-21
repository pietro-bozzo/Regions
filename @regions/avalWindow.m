function window = avalWindow(this,regs)
% avalWindow Get time windows used to compute spike avalanches

arguments
  this (1,1) regions
  regs (:,1) string = []
end

if ~this.hasAvalanches()
  error('avalWindow:MissingAvalanches','Avalanches have not been computed')
end

% find regions
try
  [~,~,~,r_indeces] = this.arrayInd([],regs);
catch ME
  throw(ME)
end

if isscalar(this.aval_window)
  window = this.aval_window;
else
  window = this.aval_window(r_indeces);
end