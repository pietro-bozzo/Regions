function ATM = brainATM(this,mode,bin,opt)
% brainATM

arguments
  this (1,1) regions
  mode (1,1) string {mustBeMember(mode,["aval","time","NEW"])} = 'aval'
  bin (1,1) {mustBeNumeric} = 30
  opt.regions (:,1) {mustBeNumeric} = []
  opt.restrict (:,2) {mustBeNumeric} = [] % WARNING: MULTIPLE INTERVALS RESTRICTION IS NOT IMPLEMENTED
  opt.duration_thresh (1,1) {mustBeNumeric,mustBeNonnegative} = 0
end

if ~this.hasAvalanches()
  error('brainATMs:MissingAvalanches','Avalanches have not been computed')
end

% get activity profiles for each region
[profiles,time] = this.avalProfiles('all',opt.regions);

% apply time restriction
if ~isempty(opt.restrict)
  valid_ind = time >= opt.restrict(1) & time <= opt.restrict(2);
  profiles = profiles(valid_ind,:);
  time = time(valid_ind);
end

Z = (profiles > 0).';
delay = 1; % FIXED FOR NOW, AS MISTAKE IN NEXT LINE: delay can cross avalanches this way
% columns 2 to end of Z
X = reshape(Z(:,1+delay:end),size(Z,1),1,size(Z,2)-delay);
% columns 1 to end - 1 of Z
Y = reshape(Z(:,1:end-delay),1,size(Z,1),size(Z,2)-delay);
% Aijt = 1 iff Zi(t+delay) = 1 and Zjt = 1
At = X.*Y;

if mode == "aval"
  % find avalanches
  profile = sum(profiles,2); % profile of whole-brain activity, i.e., sum of region firing rates
  start = find([profile(1) ~= 0 ; profile(2:end) ~= 0 & profile(1:end-1) == 0]);
  stop = find([profile(2:end) == 0 & profile(1:end-1) ~= 0 ; profile(end) ~= 0]);
  intervals = [start - 1, stop]; % get [start,stop] intervals for brain avalanches

  % apply duration threshold
  if opt.duration_thresh > 0
    valid_ind = (intervals(:,2)-intervals(:,1)) >= opt.duration_thresh / this.aval_window;
    start = start(valid_ind);
    stop = stop(valid_ind);
    intervals = intervals(valid_ind);
  end

  % compute ATMij averaging probability inside avalanches
  A = zeros(size(At,1),size(At,2),numel(start)); % ATMs for each avalanche
  for i = 1 : numel(start) % MAYBE VECTORIZABLE
    % Aijk: n of times Zi(t+delay) = 1 when Zjt = 1 in aval k
    A(:,:,i) = sum(At(:,:,start(i):stop(i)-1),3);
    % Bj: number of times when Zjt = 1
    Bj = sum(Z(:,start(i):stop(i)-1),2).';
    A(:,:,i) = A(:,:,i) ./ repmat(Bj,numel(Bj),1);
  end

  % ignore zeros in avalanche ATMs WHY??
  %A(A==0) = NaN;

  % mean ATM
  ATM = mean(A,3,"omitnan");

  % discard elements of ATM for which there less than 4 data points
  %count = sum(~isnan(A),3); % number of NaNs for each ATM element
  %ind_nan = count < 4;
  %ATM(ind_nan) = NaN;

elseif mode == "time"
  % assign each time point to a bin
  bin_ind = [1;ceil((time(2:end-1)-time(1))/bin)];
  unique_bins = unique(bin_ind);

  % compute ATM over time averaging probability inside time bins
  ATM = zeros(size(At,1),size(At,2),unique_bins(end)); % ATMs for each time bin
  for ind = unique_bins.' % VECTORIZABLE USING 4TH DIMENSION
    % Aijk: n of times Zi(t+delay) = 1 when Zjt = 1 in aval k
    ATM(:,:,ind) = sum(At(:,:,bin_ind==ind),3);
    % Bj: number of times when Zjt = 1
    Bj = sum(Z(:,bin_ind==ind),2).';
    ATM(:,:,ind) = ATM(:,:,ind) ./ repmat(Bj,numel(Bj),1);
  end

elseif mode == "NEW"
  % find avalanches
  %profile = sum(profiles,2); % profile of whole-brain activity, i.e., sum of region firing rates
  %start = find([profile(1) ~= 0 ; profile(2:end) ~= 0 & profile(1:end-1) == 0]);
  %stop = find([profile(2:end) == 0 & profile(1:end-1) ~= 0 ; profile(end) ~= 0]);
  %intervals = [start - 1, stop]; % get [start,stop] intervals for brain avalanches

  intervals = cell(numel(opt.regions),1);
  start_times = [];
  for r = 1 : numel(opt.regions)
    % get avalanches [start, stop] intervals
    region_intervals = this.avalIntervals('all',opt.regions(r),restriction=opt.restrict).';
    % apply duration threshold
    if opt.duration_thresh > 0
      valid_ind = (region_intervals(2,:)-region_intervals(1,:)) >= opt.duration_thresh;
    else
      valid_ind = true(size(region_intervals,2),1);
    end
    % store start times
    start_times = inhomogeneousVertcat(start_times,region_intervals(1,valid_ind),pad='NaN');
    % store flattened intervals to use as edges; avalanche starting times are intervals(1:2:end,:)
    valid_int = region_intervals(:,valid_ind);
    %intervals = inhomogeneousHorzcat(intervals,valid_int(:));
    intervals{r} = valid_int(:);
  end

  bin_ind = ceil(start_times/bin);
  bin_ind(bin_ind==0) = 1;
  ATM = zeros(numel(opt.regions),numel(opt.regions),max(bin_ind,[],'all')); % ATMs for each time bin
  for i = 1 : numel(intervals)
    % labels(j,k) is which aval of region i contains start time of avalanche k of region j; even labels correspond to no avalanche of region i CHECK
    labels = discretize(start_times,intervals{i}); % NOW count odds to know ratio of avals of i that begin inside j
    % per line: numel(unique(odds)) / num aval of i in bin
    normaliz = accumarray(bin_ind(i,~isnan(bin_ind(i,:))).',1);
    for j = 1 : size(labels,1)
      count = accumarray(bin_ind(j,~isnan(bin_ind(j,:))).',labels(j,~isnan(bin_ind(j,:))),[],@countUniqueOdds);
      count = count ./ normaliz;
      % ATMij: fraction of avalanches of source i which contain avalanche activations of target j
      ATM(j,i,:) = count;
    end
  end
end

end

function y = countUniqueOdds(x)
  % keep odd values  
  x = x(mod(x,2) == 1);
  % count unique values
  y = numel(unique(x));
end