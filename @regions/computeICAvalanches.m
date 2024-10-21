function this = computeICAvalanches(this, opt)
arguments
  this (1,1) regions
  opt.threshold (1,1) double {mustBeNonnegative} = 2
end
    if isempty(this.regions_array) || isempty(this.regions_array(1).neurons)
      err.message = append('Spikes are not loaded.');
      err.identifier = 'computeAvalanches:MissingSpikes';
      error(err);
    end
    for i = 1 : numel(this.regions_array)
      this.regions_array(i) = this.regions_array(i).computeICAvalanches(threshold=opt.threshold);
    end
end

