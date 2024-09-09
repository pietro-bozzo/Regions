function this = computeAvalanches(this,opt)
% computeAvalanches Compute avalanches from raw spiking data, divided by regions

arguments
  this (1,1) regions
  opt.spike_dt (1,1) double {mustBePositive} = 0.02
  opt.threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(opt.threshold,1)} = 0
  opt.save (1,1) {mustBeLogical} = false
end

% if spikes haven't been loaded
if isempty(this.regions_array) || isempty(this.regions_array(1).getNeurons)
  err.message = append('Spikes are not loaded.');
  err.identifier = 'computeAvalanches:MissingSpikes';
  error(err);
end
for i = 1 : numel(this.regions_array)
  this.regions_array(i) = this.regions_array(i).computeAvalanches(spike_dt=opt.spike_dt,threshold= ...
    opt.threshold);
end
if opt.save
  this.saveAval();
end