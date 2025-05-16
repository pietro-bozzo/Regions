function [intervals,group_ind,groups,counts,perc] = brainAvalanches(this,opt)
% brainAvalanches RENAME TO brainAvalMembers ?

arguments
  this (1,1) regions
  opt.regions (:,1) double = []
  opt.restrict (:,2) double = [] % WARNING: MULTIPLE INTERVALS RESTRICTION IS NOT IMPLEMENTED
  opt.duration_thresh (1,1) double {mustBeNonnegative} = 0 % useful if computation is long, to remove short avalanches
end

if ~this.hasAvalanches()
  error('brainAvalanches:MissingAvalanches','Avalanches have not been computed')
end

% find regions
%[~,~,~,opt.regions] = this.indeces([],opt.regions);

% % get profiles for each region
% profiles = [];
% for reg = opt.regions.'
%   [firing_rate,time] = this.firingRate('all',reg,window=this.aval_window,smooth=this.aval_smooth);
%   % threshold firing rate differently for sleep and task
%   profile = percentThreshold(firing_rate,this.aval_threshold);
%   if this.aval_event_threshold ~= this.aval_threshold
%     profile_task = percentThreshold(firing_rate,this.aval_event_threshold);
%     % assign task profile to task intervals
%     ind = false(size(time));
%     for interval = vertcat(this.phase_stamps{~contains(this.phases,"sleep")}).'
%       ind = ind | (time >= interval(1) & time <= interval(2));
%     end
%     profile(ind) = profile_task(ind);
%   end
%   profiles = inhomogeneousHorzcat(profiles,profile);
% end

% activity get profiles for each region
[profiles,time] = this.avalProfiles('all',opt.regions);

% apply time restriction
if ~isempty(opt.restrict)
  valid_ind = time >= opt.restrict(1) & time <= opt.restrict(2);
  profiles = profiles(valid_ind,:);
  time = time(valid_ind);
end

% find avalanches
profile = sum(profiles,2); % profile of whole-brain activity, i.e., sum of region firing rates
start = [profile(1) ~= 0 ; profile(2:end) ~= 0 & profile(1:end-1) == 0];
stop = [false; profile(2:end) == 0 & profile(1:end-1) ~= 0]; % stop is set at first 0 after avalanche, to use cumsum
intervals = [find(start) - 1, find([stop(2:end) ; profile(end)~=0])]; % get [start,stop] intervals for brain avalanches

% discard avalanches shorter than a threshold
if opt.duration_thresh > 0
  valid_ind = (intervals(:,2)-intervals(:,1)) >= opt.duration_thresh / this.aval_window;
  intervals = intervals(valid_ind,:);
  start = false(size(start)); % reset start
  start(intervals(:,1)+1) = true;
  stop = false(size(stop)); % reset stop
  stop(intervals(1:end-1,2)+1) = true;
  % if last interval ends at last time point, stop is not needed
  if intervals(end) ~= numel(profile)
   stop(intervals(end)) = true;
  end
end
intervals = intervals * this.aval_window + time(1); % convert intervals to seconds

% mark time steps with index of each avalanche, times outside avalanches have index 1
aval_ind = zeros(size(profile));
aval_ind(start) = 1 : sum(start);
aval_ind(stop) = -1 : -1 : -sum(stop);
aval_ind = cumsum(aval_ind) + 1;

% operate on elements of each avalanche, store results
res = zeros(size(profiles,2),sum(start)+1); % first column of res is elements outside avalanches
for i = 1 : size(profiles,2)
  res(i,:) = accumarray(aval_ind,profiles(:,i),[],@any);
end
res = res(:,2:end);
% assign an index to each type of avalanche, based on which regions appear
[grr,~,group_ind] = unique(res.','rows');
% identify different combinations
[counts,groups,perc] = groupcounts(res.');
groups = logical([groups{:}]);

% TEMPORARY CHECK
if ~all(all(grr == groups))
  warning('groups')
end