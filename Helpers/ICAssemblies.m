function [weights,otsuEigenvalues] = ICAssemblies(spikes,window,opt)
% ICAssemblies Detect assemblies via Indipendent Component Analysis and use Otsu criteria to select components

arguments
  spikes (:,2) double
  window (1,1) double {mustBePositive}
  opt.restrict (:,2) double {mustBeNonnegative} = [] % interval on which to perform ICA
  opt.units (:,1) double {mustBePositive} = [] % set of units to include in output weights, default is [1,max(units)]
end

% handle empty input
unique_units = unique(spikes(:,2));
if isempty(spikes) || numel(unique_units) == 1
  [weights,otsuEigenvalues] = deal(NaN);
  return
end

% build intervals
intervals = [];
if isempty(opt.restrict)
  opt.restrict = [spikes(1,1),spikes(end,1)];
end
for i = 1 : size(opt.restrict,1)
  intervals = [intervals;Bins(opt.restrict(i,1),opt.restrict(i,2),window,window)];
end

% compute ICA + PCA
[~,eigenvalues,ICA_weights] = ActivityTemplatesICA(spikes,'bins',intervals);
eigenvalues = eigenvalues(1:size(ICA_weights,2)); % discard eigenvalues associated to rejected components

% compute Otsu weights
weights = zeros(size(ICA_weights,1),0);
otsuEigenvalues = [];
i = 1;
for component = 1 : size(ICA_weights,2) % THIS SHOULD NOT BE A FOR, RATHER SOME CLEVER MATRIX MULTIPLICATION
  thresh = multithresh(abs(ICA_weights(:,component)));
  mask = abs(ICA_weights(:,component))>thresh;
  nNeg = sum(ICA_weights(mask,component)<0);
  if nNeg == 0 % if no negative weights
    weights(:,i) = ICA_weights(:,component);
    weights(~mask,i) = 0;
    otsuEigenvalues(i) = eigenvalues(component);
    i = i + 1;
  end
end