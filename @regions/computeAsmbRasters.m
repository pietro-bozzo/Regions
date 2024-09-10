function this = computeAsmbRasters(this,opt)
% computeAsmbRasters Compute rasters of activtiy for assemblies, divided by region

arguments
  this (1,1) regions
  opt.threshold (1,1) double {mustBeNonnegative} = 0
end

for i = 1 : numel(this.regions_array)
  this.regions_array(i) = this.regions_array(i).computeAsmbRaster(threshold=opt.threshold);
end