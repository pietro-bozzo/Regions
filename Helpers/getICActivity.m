function [otsuWeights,eigenvalues,activity,t] = getICActivity(spikes,sleepPeriod,sessionID,myFolder,opt)
%getICActivity Summary of this function goes here

arguments
  spikes (:,2) double
  sleepPeriod (:,2) double {mustBeNonnegative}
  sessionID (1,:) char
  myFolder (1,:) char
  opt.skip (1,1) {mustBeLogical} = false
  opt.save (1,1) {mustBeLogical} = false
  opt.windowsize (1,1) double {mustBePositive} = 0.03
end

% skip if already existing
if opt.skip == true && exist([myFolder '/' sessionID '-weights15ms']) == 2
  weights = dlmread([myFolder '/' sessionID '-weights15ms']);
  eigenvalues = dlmread([myFolder '/' sessionID '-eigenvalues15ms']);
  otsuWeights = dlmread([myFolder '/' sessionID '-otsuWeights']);
  peaks = dlmread([myFolder '/' sessionID '-peaks']);
  fprintf(1,append('Skipping ',sessionID,', ICA already computed.\n'))
  return
end

% build intervals
intervals = [];
for i = 1 : size(sleepPeriod,1)
  intervals = [intervals;Bins(sleepPeriod(i,1),sleepPeriod(i,2),opt.windowsize,opt.windowsize)];
end

% relabel units to a {1,...,N} set, preserving unit order
[~,~,spikes(:,2)] = unique(spikes(:,2));

% compute ICA + PCA      MAYBE REPLACE WITH f THAT ONLY DOES weights?
[~,eigenvalues,weights] = ActivityTemplatesICA(spikes,'bins',intervals);

% compute Otsu weigths   MUST UPDATE EIGENVALUES
otsuWeights = []; count = 0;
for assembly = 1 : size(weights,2)
  thresh = multithresh(abs(weights(:,assembly)));
  m = abs(weights(:,assembly))>thresh;
  nNeg = sum(weights(m,assembly)<0);
  if nNeg == 0 % if no negative weights
    count = count + 1;
    otsuWeights(:,count) = weights(:,assembly);
    otsuWeights(~m,count) = 0;
  end
end

% compute Otsu templates
templates = zeros(size(otsuWeights,1),size(otsuWeights,1),size(otsuWeights,2));
for i = 1 : size(otsuWeights,2) % THIS SHOULD NOT BE A FOR
  templates(:,:,i) = otsuWeights(:,i)*otsuWeights(:,i)';
  templates(:,:,i) = templates(:,:,i) - diag(diag(templates(:,:,i))); % remove the diagonal
end

% compute activation strength
step = 0.001; % COULD BE USED TO RECALCULATE BINS AS FOLLOWS
% for i = 1 : size(sleepPeriod,1)
%   intervals = [intervals;Bins(sleepPeriod(i,1),sleepPeriod(i,2),opt.windowsize,STEP)];
% end
activity = ReactivationStrength(spikes,templates,'bins',intervals);
activity = Restrict(activity,sleepPeriod);
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