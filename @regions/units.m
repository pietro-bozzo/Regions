function [list,regs] = units(this,regs)
% nNeurons Get pooled list of units for regions

arguments
  this (1,1) regions
  regs (:,1) string = []
end

if ~this.hasSpikes()
  error('nNeurons:MissingSpikes','Spikes have not been loaded')
end

% find regions
try
  [~,regs,~,r_indeces] = this.arrayInd([],regs);
catch ME
  throw(ME)
end

list = [];
for r = r_indeces
  list = [list;this.regions_array(r).neurons];
end