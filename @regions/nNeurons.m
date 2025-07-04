function [list,regs] = nNeurons(this,regs)
% nNeurons Get list of number of neurons for requested regions

arguments
  this (1,1) regions
  regs (:,1) double = []
end

if ~this.hasSpikes()
  error('nNeurons:MissingSpikes','Spikes have not been loaded')
end

% find requested regions
[~,r_indeces,~,regs] = this.indeces([],regs);

list = [];
for r = r_indeces
  list = [list;numel(this.regions_array(r).neurons)];
end