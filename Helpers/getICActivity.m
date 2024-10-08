function [otsuWeights,otsuEigenvalues,activity,t] = getICActivity(spikes,opt)
% getICActivity Perform Indipendent Component Analysis and use Otsu criteria to discard some components 

arguments
  spikes (:,2) double
  opt.restrict (:,2) double {mustBeNonnegative} = []
  opt.windowsize (1,1) double {mustBePositive} = 0.05
  opt.skip (1,1) {mustBeLogical} = false
  opt.save (1,1) {mustBeLogical} = false
  opt.path (1,:) char = '' % path to save results to, NOT YET IMPLEMENTED
end

% skip if already existing TO IMPLEMENT IF SAVING OF ICA IS NEEDED FOR SPEED
% if opt.skip == true && exist([myFolder '/' sessionID '-weights15ms']) == 2
%   weights = dlmread([myFolder '/' sessionID '-weights15ms']);
%   eigenvalues = dlmread([myFolder '/' sessionID '-eigenvalues15ms']); NAME CHANGED
%   otsuWeights = dlmread([myFolder '/' sessionID '-otsuWeights']);
%   peaks = dlmread([myFolder '/' sessionID '-peaks']);
%   fprintf(1,append('Skipping ',sessionID,', ICA already computed.\n'))
%   return
% end

if isempty(spikes) || numel(unique(spikes(:,2))) == 1
  [otsuWeights,otsuEigenvalues,activity,t] = deal(NaN);
  return
end

% build intervals
intervals = [];
if isempty(opt.restrict)
  opt.restrict = [0,spikes(end,1)];
end
for i = 1 : size(opt.restrict,1)
  intervals = [intervals;Bins(opt.restrict(i,1),opt.restrict(i,2),opt.windowsize,opt.windowsize)];
end

% relabel units to a {1,...,N} set, preserving unit order
[~,~,spikes(:,2)] = unique(spikes(:,2));

% compute ICA + PCA
[~,eigenvalues,weights] = ActivityTemplatesICA(spikes,'bins',intervals);
eigenvalues = eigenvalues(1:size(weights,2)); % discard eigenvalues associated to rejected components

% compute Otsu weigths
otsuWeights = [];
otsuEigenvalues = [];
i = 1;
for component = 1 : size(weights,2)
  thresh = multithresh(abs(weights(:,component)));
  mask = abs(weights(:,component))>thresh;
  nNeg = sum(weights(mask,component)<0);
  if nNeg == 0 % if no negative weights
    otsuWeights(:,i) = weights(:,component);
    otsuWeights(~mask,i) = 0;
    otsuEigenvalues(i) = eigenvalues(component);
    i = i + 1;
  end
end

% compute Otsu templates
templates = zeros(size(otsuWeights,1),size(otsuWeights,1),size(otsuWeights,2));
for i = 1 : size(otsuWeights,2) % THIS SHOULD NOT BE A FOR, RATHER SOME CLEVER MATRIX MULTIPLICATION
  templates(:,:,i) = otsuWeights(:,i)*otsuWeights(:,i)';
  templates(:,:,i) = templates(:,:,i) - diag(diag(templates(:,:,i))); % remove the diagonal
end

% compute activation strength
% step = 0.001; % COULD BE USED TO RECALCULATE BINS AS FOLLOWS
% for i = 1 : size(opt.restrict,1)
%   intervals = [intervals;Bins(opt.restrict(i,1),opt.restrict(i,2),opt.windowsize,STEP)];
% end
activity = ReactivationStrength(spikes,templates,'bins',intervals);
activity = Restrict(activity,opt.restrict); % DOES THIS LINE EVER CHANGE ANYTHING? AS I ALREADY CREATE 
% INTERVALS USING opt.restrict
t = activity(:,1); % save first column as time
activity(:,1) = []; % remove first column

% % Define threshold
% q = 0.95; Quantile =  [];
% for ii = 1:size(activity,2)
%     Quantile(ii,1) = quantile(activity(activity(:,ii)>median(activity(:,ii)),ii),q);
% end
% 
% % Find peaks
% id = []; stamps = [];
% for assembly = 1:size(otsuWeights,2)
%     %[~,peaks] = findpeaks(activity(:,assembly),'MinPeakHeight',Quantile(assembly,1));
%     peaks = t(FindInterval(activity(:,assembly)>=Quantile(assembly,1))); if size(peaks,2)==1, peaks = peaks'; end
%     peaks = peaks(:,1) + (peaks(:,2)-peaks(:,1))/2;
%     stamps = [stamps;peaks];
%     id = [id; assembly * ones(size(peaks,1),1)];
% end
% peaks = sortrows([stamps id]);