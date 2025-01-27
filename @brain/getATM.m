function ATM = getATM(this,delay,opt)
% getATM Compute Avalanche Transition Matrix using IC activity from each region

arguments
  this (1,1) brain
  delay (1,1) double {mustBePositive,mustBeInteger} = 1
  opt.threshold (1,1) double {mustBeNonnegative} = 0
  opt.restrict (:,2) double {mustBeNonnegative} = []
  opt.shuffle (1,1) {mustBeLogical} = false
  opt.concatenate (1,1) {mustBeLogical} = false
end

if isempty(this.ICs_binar_activity)
  error('getATM:MissingBinActivity','Binarized activity wasn''t computed.');
end

%this.ATM_stamps{end+1,1} = opt.restrict; % store intervals over which ATM is computed DEPRECATED
% convert to full matrix to use accumarray CONVERSION IS TIME CONSUMING, ARE sparse MATRICES REALLY NEEDED?
if issparse(this.ICs_binar_activity)
  Z = full(this.ICs_binar_activity).';
else
  Z = this.ICs_binar_activity.';
end

% apply restriction
if ~isempty(opt.restrict)
  ind_restrict = false(size(Z,2),1);
  time = (0.5 : size(Z,2)).' * this.IC_bin_size;
  for i = 1 : size(opt.restrict,1)
    ind_restrict = ind_restrict | (time >= opt.restrict(i,1) & time <= opt.restrict(i,2));
  end
  Z = Z(:,ind_restrict); % SHOUL MAYBE ADD ZERO COLUMNS AFTER EACH RESTRICT
end

% shuffle
if opt.shuffle % shuffle activity matrix preserving inter-event interval per row
  Z = shuffleSpikeMatrix(Z); % IF RESTRICT HAS HOLES IN IT, IT SHOULD BE PASSED TO shuffleSpikeMatrix
end

% columns 2 to end of Z
X = reshape(Z(:,1+delay:end),size(Z,1),1,size(Z,2)-delay); % MISTAKE: delay can cross avalanches this way
% columns 1 to end - 1 of Z
Y = reshape(Z(:,1:end-delay),1,size(Z,1),size(Z,2)-delay);
% Aijt = 1 iff Zi(t+delay) = 1 and Zjt = 1
At = X.*Y;
% avalanches profile
profile = sum(Z(:,1:end-delay),1).';
start = find([profile(1)~=0;profile(2:end)~=0&profile(1:end-1)==0]);
stop =  find([profile(2:end)==0&profile(1:end-1)~=0;profile(end)~=0]);
% remove avalanches lasting less than 6 time bins
%ind_duration = stop - start + 1 >= 6; % USE opt.threshold
%start = start(ind_duration);
%stop = stop(ind_duration);

if opt.concatenate
  % compute ATMij considering probability over all time bins in avalanches
  aval_indeces = zeros(size(profile));
  aval_indeces(start) = 1;
  aval_indeces(stop) = aval_indeces(stop) - 1;
  aval_indeces = logical(cumsum(aval_indeces)); % last time bin of each avalanche is ignored, ok as At is 0 and spikes should not contribute to Bj
  A = sum(At(:,:,aval_indeces),3);
  Bj = sum(Z(:,aval_indeces),2).';
  this.ATMs(end+1,:,:) = A ./ repmat(Bj,numel(Bj),1);
else
  % compute ATMij averaging probability across avalanches
  A = zeros(size(At,1),size(At,2),numel(start)); % ATMs for each avalanche
  for i = 1 : numel(start) % MAYBE VECTORIZABLE
    % Aijk: n of times Zi(t+delay) = 1 when Zjt = 1 in aval k
    A(:,:,i) = sum(At(:,:,start(i):stop(i)-1),3);
    % Bj: number of times when Zjt = 1
    Bj = sum(Z(:,start(i):stop(i)-1),2).';
    A(:,:,i) = A(:,:,i) ./ repmat(Bj,numel(Bj),1);
  end
  % ignore zeros in avalanche ATMs
  %A(A==0) = NaN;
  % mean ATM
  ATM = mean(A,3,"omitnan");
  % discard elements of ATM for which there less than 4 data points
  count = sum(~isnan(A),3); % number of NaNs for each ATM element
  ind_nan = count < 4;
  ATM(ind_nan) = NaN;
end

% set NaNs as zeros
ATM(isnan(ATM)) = 0;