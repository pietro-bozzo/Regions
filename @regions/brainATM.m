function ATM = brainATM(this,opt)
% brainATM

arguments
  this (1,1) regions
  opt.regions (:,1) double = []
  opt.restrict (:,2) double = [] % WARNING: MULTIPLE INTERVALS RESTRICTION IS NOT IMPLEMENTED
  opt.duration_thresh (1,1) double {mustBeNonnegative} = 0
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

Z = (profiles > 0).';
delay = 1; % FIX FOR NOW, AS MISTAKE IN NEXT LINE: delay can cross avalanches this way
% columns 2 to end of Z
X = reshape(Z(:,1+delay:end),size(Z,1),1,size(Z,2)-delay);
% columns 1 to end - 1 of Z
Y = reshape(Z(:,1:end-delay),1,size(Z,1),size(Z,2)-delay);
% Aijt = 1 iff Zi(t+delay) = 1 and Zjt = 1
At = X.*Y;

% compute ATMij averaging probability across avalanches
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