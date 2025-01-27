function [activations,activity,t] = ICActivations(spikes,weights,window,opt)
% ICActivations Compute assemblies activations from spikes and assembly weights

arguments
  spikes (:,2) double                                % EXPLAIN, unit 1 is assumed to correspond to first row of weights
  weights (:,:) double
  window (1,1) double {mustBePositive}
  opt.restrict (:,2) double {mustBeNonnegative} = [] % interval on which to compute activations
end

% handle empty input
unique_units = unique(spikes(:,2));
if isempty(spikes) || numel(unique_units) == 1 || isempty(weights)
  activations = [NaN,NaN];
  [activity,t] = deal(NaN);
  return
end
if max(unique_units) > size(weights,1)
  error('ICActivations:MissingUnits','Argument spikes contains more units than rows of argument weights.')
end

% compute templates
templates = zeros(size(weights,1),size(weights,1),size(weights,2));
for i = 1 : size(weights,2) % THIS SHOULD NOT BE A FOR, RATHER SOME CLEVER MATRIX MULTIPLICATION
  templates(:,:,i) = weights(:,i) * weights(:,i)';
  templates(:,:,i) = templates(:,:,i) - diag(diag(templates(:,:,i))); % remove diagonal
end

% build overlapping time bins
intervals = [];
if isempty(opt.restrict)
  opt.restrict = [spikes(1,1),spikes(end,1)];
end
for i = 1 : size(opt.restrict,1)
  intervals = [intervals;Bins(round(opt.restrict(i,1)),opt.restrict(i,2),window,window/2)]; % round is used to have nicer time bins
end

% compute activation strength
activity = ReactivationStrength(spikes,templates,'bins',intervals);
t = activity(:,1); % save first column as time
activity(:,1) = []; % remove first column

% compute activations list
q = 0.95; Quantile =  [];
for ii = 1:size(activity,2)
    Quantile(ii,1) = quantile(activity(activity(:,ii)>median(activity(:,ii)),ii),q);
end
% Find peaks
id = []; stamps = [];
for assembly = 1:size(activity,2)
    %[~,peaks] = findpeaks(activity(:,assembly),'MinPeakHeight',Quantile(assembly,1));
    activations = t(FindInterval(activity(:,assembly)>=Quantile(assembly,1)));
    if ~isempty(activations)
      if size(activations,2)==1
        activations = activations';
      end
      activations = activations(:,1) + (activations(:,2)-activations(:,1))/2;
      stamps = [stamps;activations];
      id = [id; assembly * ones(size(activations,1),1)];
    end
end
activations = sortrows([stamps id]);