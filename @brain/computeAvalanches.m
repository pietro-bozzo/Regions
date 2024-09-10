function this = computeAvalanches(this,opt)
% computeAvalanches Compute avalanches using IC activity of each region

arguments
  this (1,1) brain
  opt.threshold (1,1) double {mustBeNonnegative} = 0
end

this.aval_threshold = opt.threshold;
profile = sum(abs(zscore(this.ICs_activity))>opt.threshold,2);
this.aval_profile = profile;
ind = [true;profile(2:end)~=0|profile(1:end-1)~=0]; % ind(i) = 0 if i is repeated zero
% compute sizes
clean = profile(ind); % remove repeated zeros
this.aval_sizes = accumarray(cumsum(clean==0)+(profile(1)~=0),clean);
if this.aval_sizes(end) == 0 % remove last zero
  this.aval_sizes = this.aval_sizes(1:end-1);
end
% compute indeces of avalanche initiation and ending times
this.aval_indeces = [find([profile(1)~=0;profile(2:end)~=0&profile(1:end-1)==0]), ...
  find([profile(2:end)==0&profile(1:end-1)~=0;profile(end)~=0])];