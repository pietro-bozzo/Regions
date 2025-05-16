function [sizes,intervals,timeDependentSize] = avalanchesFromProfile(profile,time_step)
% avalanchesFromProfile Compute avalanches sizes and [start,end] intervals from population activity
%
% arguments:
%     profile      double, activity profile
%     time_step    double, time step of profile trace, assumed to start at time 0 s
%
% output:
%     sizes        (n_avals,1) double, avalanche sizes
%     intervals    (n_avals,2) double, each row is an avalanche's [start,end] interval

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  profile (:,1) double {mustBeNonnegative}
  time_step (1,1) double {mustBePositive}
end

if isempty(profile)
  [sizes,timeDependentSize] = deal(NaN);
  intervals = [NaN,NaN];
else
  ind = [true;profile(2:end)~=0|profile(1:end-1)~=0]; % ind(i) = 0 if i is repeated zero
  % compute sizes
  clean = profile(ind); % remove repeated zeros
  sizes = accumarray(cumsum(clean==0)+(profile(1)~=0),clean);
  timeDependentSize = clean;
  if sizes(end) == 0 % remove last zero
    sizes = sizes(1:end-1);
  end
  % compute avalanche start and end times
  intervals = [find([profile(1)~=0;profile(2:end)~=0&profile(1:end-1)==0]) - 1, find([profile(2:end)==0&profile(1:end-1)~=0;profile(end)~=0])] * time_step;
end