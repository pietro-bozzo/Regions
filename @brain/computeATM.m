function this = computeATM(this,opt)
% computeATM Compute Avalanche Transition Matrix using IC activity from each region

arguments
  this (1,1) brain
  opt.threshold (1,1) double {mustBeNonnegative} = 0
  opt.restrict (:,2) double {mustBeNonnegative} = []
  opt.shuffle (1,1) {mustBeLogical} = false
end

this = this.setAvalThreshold(opt.threshold);
% store intervals on which to compute ATM
this.ATM_stamps{end+1,1} = opt.restrict;
Z = this.ICs_binar_activity.';
% apply restriction
if ~isempty(opt.restrict)
  indeces = false(size(this.ICs_activity,1),1);
  for i = 1 : size(opt.restrict,1)
    indeces = indeces | (this.IC_time >= opt.restrict(i,1) & this.IC_time <= opt.restrict(i,2));
  end
  Z(:,~indeces) = 0;
end
% shuffle
if opt.shuffle % shuffle activity matrix preserving inter-event interval per row
  Z = shuffleSpikeMatrix(Z); % IF RESTRICT HAS HOLES IN IT, IT SHOULD BE PASSED TO shuffleSpikeMatrix
end
% columns 2 to end of Z
X = reshape(Z(:,2:end),size(Z,1),1,size(Z,2)-1);
% columns 1 to end - 1 of Z
Y = reshape(Z(:,1:end-1),1,size(Z,1),size(Z,2)-1);
% Aijt = 1 iff Zi(t+1) = 1 and Zjt = 1
At = X.*Y;
% avalanches profile
profile = sum(Z,1).';
start = find([profile(1)~=0;profile(2:end)~=0&profile(1:end-1)==0]);
stop =  find([profile(2:end)==0&profile(1:end-1)~=0;profile(end)~=0]);
A = zeros(size(At,1),size(At,2),numel(start));
for i = 1 : numel(start)
  % remove avalanches lasting less than 4 time bins
  if stop(i) - start(i) + 1 < 4
    A(:,:,i) = NaN;
  else
    % Aijk: n of times Zi(t+1) = 1 when Zjt = 1 in aval k
    A(:,:,i) = sum(At(:,:,start(i):stop(i)-1),3);
    % Bj: number of times when Zjt = 1
    Bj = sum(Z(:,start(i):stop(i)-1),2).';
    A(:,:,i) = A(:,:,i) ./ repmat(Bj,numel(Bj),1);
  end
end
this.ATMs(end+1,:,:) = mean(A,3,"omitnan");
% discard elements of ATM for which there less than 4 data points
count = sum(~isnan(A),3); % number of NaNs for each ATM element
indeces = count < 4;
this.ATMs(end,indeces) = NaN;
%this.ATMs(end,isnan(this.ATMs(end,:,:))) = 0; set NaNs as zeros DEPRECATED