function value = hasSpikes(this)
% hasSpikes Return true iff spikes have already been loaded

if isempty(this.regions_array)
  value = false;
else
  value = true;
end