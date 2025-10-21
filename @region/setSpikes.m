function this = setSpikes(this,spikes)
% setSpikes Set spikes member of the region object

arguments
  this (1,1) region
  spikes (:,2) {mustBeNumeric}
end

this.spikes = spikes;