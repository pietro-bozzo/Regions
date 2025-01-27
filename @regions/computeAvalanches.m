function this = computeAvalanches(this,opt)
% computeAvalanches Compute avalanches per region from raw spiking data

arguments
    this (1,1) regions
    opt.spike_dt (1,1) double {mustBePositive} = 0.01
    opt.threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(opt.threshold,1)} = 0
    opt.save (1,1) {mustBeLogical} = false
    opt.dopc = false
    opt.pc = NaN
    opt.var = 0.5
    opt.first = true
    opt.pcPercentile = 10
end

% if spikes haven't been loaded
if isempty(this.regions_array) || isempty(this.regions_array(1).neurons)
  err.message = append('Spikes are not loaded.');
  err.identifier = 'computeAvalanches:MissingSpikes';
  error(err);
end

n = numel(this.regions_array);
f = waitbar(0, sprintf('Sending jobs (%d/%d)', 0, n));
future(1:10) = parallel.FevalFuture;
for i = 1 : numel(this.regions_array)
  future(i) = parfeval(@computeTask, 1, this.regions_array(i), opt.spike_dt,...
    opt.threshold, opt.dopc, opt.pc, opt.var, opt.first, opt.pcPercentile);
  waitbar(i / n, f, sprintf('Sending jobs (%d/%d)', i, n));
end
waitbar(0, f, 'Pending...');
for i = 1:numel(this.regions_array)
    [completedIdx,r] = fetchNext(future);
    this.regions_array(completedIdx) = r;
    waitbar(i /n, f, sprintf('Computing (%d/%d)', i, n));
end
if opt.save
  this.saveAval();
end
close(f);
end

function newr = computeTask(r, spike_dt, threshold, dopc, pc, var, first, pcPercentile)
    newr = r.computeAvalanches(spike_dt=spike_dt,threshold= ...
    threshold, dopc=dopc, pc=pc, var=var, first=first, pcPercentile=pcPercentile);
end