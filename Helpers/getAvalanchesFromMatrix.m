function [aval_sizes,profile,aval_indeces, aval_timeDependendentSize] = getAvalanchesFromMatrix(n0, opt)
arguments
  n0
  opt.percentile (1,1) double {mustBeNonnegative} = 10
end

profile = sum(n0,2);
theta = prctile(profile, opt.percentile);
profile = profile - theta;
profile(profile < 0) = 0;
ind = [true;profile(2:end)>0|profile(1:end-1)>0]; % ind(i) = 0 if i is repeated < zero
% compute sizes
clean = profile(ind); % remove repeated < zeros
aval_sizes = accumarray(cumsum(clean==0)+(profile(1)~=0),clean);
if aval_sizes(end) == 0 % remove last zero
  aval_sizes = aval_sizes(1:end-1);
end
% compute indeces of avalanche initiation and ending times
aval_indeces = [find([profile(1)~=0;profile(2:end)~=0&profile(1:end-1)==0]), ...
  find([profile(2:end)==0&profile(1:end-1)~=0;profile(end)~=0])];
aval_timeDependendentSize = clean;
aval_sizes = round(aval_sizes) + 1;
end