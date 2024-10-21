function [sizes,profile,indeces,durations, timeDependentSize] = getAvalanchesFromList(spikes,bin_size,opt)
% getAvalanchesFromList Get avalanches sizes, activity profile and start/end indeces from spike list
%
% arguments:
% spikes (:,2) double {mustBeNonnegative}      matrix having sorted time stamps as first column and unit ids as
%                                              second
% bin_size (1,1) double {mustBeNonnegative}    bin size for time discretization
% threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(1)} = 0    percentile of the activity profile
%                                              to be used as threshold for avalanche detection

arguments
    spikes (:,2) double {mustBeNonnegative}
    bin_size (1,1) double {mustBeNonnegative}
    opt.threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(opt.threshold,1)} = 0
end

if isempty(spikes)
  [sizes,profile, durations, timeDependentSize] = deal(NaN);
  indeces = [NaN,NaN];
else
  edges = 0 : bin_size : spikes(end,1)+bin_size;
  profile = histcounts(spikes(:,1),edges).';
  if opt.threshold ~= 0
    sorted = sort(profile(profile~=0)); % sort avalanche profile values
    threshold = sorted(ceil(opt.threshold*size(sorted,1))); % get threshold as a percentile of profile
    profile = profile - threshold;
    profile(profile<0) = 0;
  end
  ind = [true;profile(2:end)~=0|profile(1:end-1)~=0]; % ind(i) = 0 if i is repeated zero
  % compute sizes
  clean = profile(ind); % remove repeated zeros
  timeDependentSize = clean;
  sizes = accumarray(cumsum(clean==0)+(profile(1)~=0),clean);
  % compute durations
  clean = profile(ind) > 0; % remove repeated zeros and count each active bin as 1
  durations = accumarray(cumsum(clean==0)+(profile(1)~=0),clean);
  if sizes(end) == 0 % remove last zero
    sizes = sizes(1:end-1);
    durations = durations(1:end-1);
  end
  % compute indeces of avalanche initiation and ending times
  indeces = [find([profile(1)~=0;profile(2:end)~=0&profile(1:end-1)==0]), ...
    find([profile(2:end)==0&profile(1:end-1)~=0;profile(end)~=0])];
end