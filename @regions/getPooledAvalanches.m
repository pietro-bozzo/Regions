function [sizes,durations] = getPooledAvalanches(this,opt)
% getPooledAvalanches Pool spike avalanches computed by region

arguments
  this (1,1) regions
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
  opt.threshold (1,1) double {mustBeNonnegative} = 0
end

% find requested states and regions
[i_indeces,j_indeces] = this.getIndeces(opt.states,opt.regions,strict=false);
sizes = [];
durations = [];
for i = i_indeces
  for j = j_indeces
    if opt.threshold == 0 || this.regions_array(i,j).getNNeurons > opt.threshold
      sizes = [sizes;this.regions_array(i,j).getAvalSizes()];
      %durations = [durations;this.regions_array(i,j).getAvalDurations()]; DEPRECATED
    end
  end
end