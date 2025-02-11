function TM = getTM(this,window,lag,opt)
% getATM Compute Transition Matrix using IC activity from each region

arguments
  this (1,1) brain
  window (1,1) double {mustBePositive}
  lag (1,1) double {mustBeNonnegative} = 0
  opt.restrict (:,2) double {mustBeNonnegative} = []
  opt.shuffle (1,1) {mustBeLogical} = false
end

if isempty(this.ICs_activations)
  error('getTM:MissingICActivations','ICs activations weren''t computed.');
end
activations = this.ICs_activations;

% apply restriction
for i = 1 : size(opt.restrict,1)
  activations = activations(activations(:,1) >= opt.restrict(i,1) & activations(:,1) <= opt.restrict(i,2),:); % CHECK
end

% shuffle NOT IMPLEMENTED
%if opt.shuffle % shuffle activity matrix preserving inter-event interval per row
%  Z = shuffleSpikeMatrix(Z); % IF RESTRICT HAS HOLES IN IT, IT SHOULD BE PASSED TO shuffleSpikeMatrix
%end

% compute TM
N = sum(this.getIClist());
times = cell(N,1); % activation times divided by unit
TM = NaN(N);
% CREATE f THAT BUILDS DICTIONARY OF timesi
for i = 1 : N
  [times1,times] = getTimes(times,i,activations); % activation times of first unit
  if ~isempty(times1)
    intervals = [times1+lag,times1+window+lag].';
    ind = intervals(1,2:end) < intervals(2,1:end-1); % indeces of overlapping intervals
    % remove overlap in intervals by shortening first one
    intervals(2,[ind,false]) = intervals(1,[false,ind]) - 0.000001;
    for j = 1 : N  
      if i == j
        TM(i,j) = sum(ind) / numel(times1);
      else
        % discretize
        [times2,times] = getTimes(times,j,activations); % activation times of second unit
        pos = discretize(times2,intervals(:));
        pos = pos(~isnan(pos)); % keep only activations inside intervals
        pos = pos(rem(pos,2)~=0); % keep only odd intervals: activations inside windows
        n_j = numel(pos); % number of activations of j falling in windows
        n_i = numel(unique(pos)); % number of windows containing activations of j
        if isempty(n_i), n_i = 0; end
        TM(i,j) = sqrt(n_j * n_i / numel(times1) / numel(times2)); % square root of (fraction of activations of j falling in windows * fraction of windows containing activations of j)
      end
    end
  end
end
% set NaNs as zeros
TM(isnan(TM)) = 0;

function [times,times_dict] = getTimes(times_dict,i,activations)
  if isempty(times_dict{i})
    times_dict{i} = activations(activations(:,2)==i,1);
  end
  if isempty(times_dict{i})
    times_dict{i} = -1;
  end
  times = times_dict{i};
  if times == -1
    times = [];
  end