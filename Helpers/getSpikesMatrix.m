function n0 = getSpikesMatrix(spikes,opt)
arguments
  spikes (:,2) double
  opt.restrict (:,2) double {mustBeNonnegative} = []
  opt.windowsize (1,1) double {mustBePositive} = 0.01
end
    bins = [];
    if isempty(opt.restrict)
      opt.restrict = [0,spikes(end,1)];
    end
    for i = 1 : size(opt.restrict,1)
      bins = [bins;Bins(opt.restrict(i,1),opt.restrict(i,2),opt.windowsize,opt.windowsize)];
    end
    
    % relabel units to a {1,...,N} set, preserving unit order
    [~,~,spikes(:,2)] = unique(spikes(:,2));
    

    spikes = sortrows(spikes,1);
    id = spikes(:,2);
    
    % Shift spike times to start at 0, and list bins unless explicitly provided
    if isempty(bins)
        spikes(:,1) = spikes(:,1) - spikes(1,1);
        bins = (0:step:(spikes(end,1)-binSize))';
        bins(:,2) = bins+binSize;
    else
        m = min([min(spikes(:,1)) min(bins(:))]);
        spikes(:,1) = spikes(:,1) - m;
        bins = bins - m;
    end
    
    % Create spike count matrix
    nUnits = max(spikes(:,2));
    nBins = size(bins,1);
    if isempty(nBins), return; end
    n0 = zeros(nBins,nUnits);
    for unit = 1:nUnits
        n0(:,unit) = CountInIntervals(spikes(id==unit,1),bins);
    end
end

