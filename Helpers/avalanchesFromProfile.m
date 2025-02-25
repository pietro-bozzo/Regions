function [sizes,intervals,timeDependentSize] = avalanchesFromProfile(profile,time_step,threshold)
% avalanchesFromProfile Compute avalanches sizes and [start,end] intervals from population activity
%
% arguments:
% profile (:,1) double                       population activity profile
% time_step (1,1) double {mustBePositive}    time step of profile trace, assumed to start at time 0 s
% threshold (1,1) double = 0                 percentile of profile used as threshold for avalanche detection, must be in [0,100]

arguments
  profile (:,1) double
  time_step (1,1) double {mustBePositive}
  threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(threshold,100)} = 0
end

if isempty(profile)
  [sizes,timeDependentSize] = deal(NaN);
  intervals = [NaN,NaN];
else
  threshold = prctile(profile,threshold) % ADD OPTION FOR DOUBLE SIDE THRESHOLDING TO INCREASE GENERALITY
  profile = profile - threshold;
  profile(profile<0) = 0;
  ind = [true;profile(2:end)~=0|profile(1:end-1)~=0]; % ind(i) = 0 if i is repeated zero
  % compute sizes
  clean = profile(ind); % remove repeated zeros
  sizes = accumarray(cumsum(clean==0)+(profile(1)~=0),clean);
  timeDependentSize = clean;
  % compute durations DEPRECATED
  %clean = profile(ind) > 0; % remove repeated zeros and count each active time step as 1
  %durations = accumarray(cumsum(clean==0)+(profile(1)~=0),clean) * time_step;
  if sizes(end) == 0 % remove last zero
    sizes = sizes(1:end-1);
    %durations = durations(1:end-1);
  end
  % compute indeces of avalanche initiation and ending times
  intervals = [find([profile(1)~=0;profile(2:end)~=0&profile(1:end-1)==0]) - 1, find([profile(2:end)==0&profile(1:end-1)~=0;profile(end)~=0])] * time_step;
end