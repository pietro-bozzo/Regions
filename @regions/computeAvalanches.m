function this = computeAvalanches(this,opt)
% computeAvalanches Compute avalanches from raw spiking data, divided by regions

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
    opt.verbose = true
end

% if spikes haven't been loaded
if isempty(this.regions_array) || isempty(this.regions_array(1).neurons)
  err.message = append('Spikes are not loaded.');
  err.identifier = 'computeAvalanches:MissingSpikes';
  error(err);
end

n = numel(this.regions_array);
if opt.verbose
    f = waitbar(0, sprintf('Sending jobs (%d/%d)', 0, n));
end
future(1:n) = parallel.FevalFuture;
for i = 1 : n
  future(i) = parfeval(@computeTask, 1, this.regions_array(i), opt.spike_dt,...
    opt.threshold, opt.dopc, opt.pc, opt.var, opt.first, opt.pcPercentile);
  if opt.verbose
    waitbar(i / n, f, sprintf('Sending jobs (%d/%d)', i, n));
  end
end
if opt.verbose
    waitbar(0, f, 'Pending...');
end
for i = 1:numel(this.regions_array)
    [completedIdx,r] = fetchNext(future);
    this.regions_array(completedIdx) = r;
    if opt.verbose
        waitbar(i /n, f, sprintf('Computing (%d/%d)', i, n));
    end
end
if opt.save
  this.saveAval();
end
if opt.verbose
    close(f);
end
end

function newr = computeTask(r, spike_dt, threshold, dopc, pc, var, first, pcPercentile)
    newr = r.computeAvalanches(spike_dt=spike_dt,threshold= ...
    threshold, dopc=dopc, pc=pc, var=var, first=first, pcPercentile=pcPercentile);
end