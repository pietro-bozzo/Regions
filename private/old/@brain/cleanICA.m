function this = cleanICA(this,opt)
% shuffleICA Clean ICs binarized activity removing inactive components

arguments
  this (1,1) brain
  opt.percentile (1,1) double {mustBePositive,mustBeLessThanOrEqual(opt.percentile,1)} = 0.0005 % default keeps ICs which are active at least 0.05% of the time
  opt.verbose (1,1) {mustBeLogical} = false
end

if isempty(this.ICs_binar_activity)
  error('cleanICA:MissingBinActivity','Binarized activity wasn''t computed.');
end
% clean activity
thr = size(this.ICs_binar_activity,1) * opt.percentile;
n_activations = sum(this.ICs_binar_activity,1).';
indeces = n_activations > thr;
if sum(indeces) == 0
  error('cleanICA:EmptyICActivity','Non of the ICs passed the required activations fraction.');
end
start = 1; % index where to start considering incedes for a region
count = zeros(size(this.IC_weights));
for i = 1 : numel(this.IC_weights)
  stop = start + size(this.IC_weights{i},2) - 1; % index where to stop considering incedes for a region
  this.IC_weights{i} = this.IC_weights{i}(:,indeces(start:stop));
  count(i) = sum(~indeces(start:stop));
  start = stop + 1;
end
%this.ICs_activity = this.ICs_activity(:,indeces); DEPRECATED, MUST BE SUBSTITUTED BT SMT THAT CLEANS ICs_activations!!
this.ICs_binar_activity = this.ICs_binar_activity(:,indeces);
if opt.verbose
  fprintf(1,append('Removed ICs per region: [',strjoin(string(count),','),'].\n'))
end