function maxes = binMaxAvalanches(this,bin_size,opt)
% binMaxAvalanches Bin avalanche sizes over time, keeping only max in each bin

arguments
  this (1,1) regions
  bin_size (1,1) double {mustBePositive}
  opt.states (:,1) string = []
  opt.regions (:,1) double = []
end

[i_indeces,j_indeces] = this.getIndeces(opt.states,opt.regions,strict=false);
maxes = [];
for i = i_indeces
  for j = j_indeces
    maxes = [maxes;this.regions_array(i,j).binMaxAvalanches(bin_size)];
  end
end