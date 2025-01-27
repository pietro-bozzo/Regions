function [weights,assembly_sizes] = callISAC(spikes,window,opt)
% callISAC Call ISAC to detect cell assemblies
%
% arguments:
% spikes (:,2) double                     matrix having sorted time stamps as first column and units as second
% window (1,1) double {mustBePositive}    time window to detect neuron coactivations

arguments
  spikes (:,2) double
  window (1,1) double {mustBePositive}
  opt.restrict (:,2) double {mustBeNonnegative} = [] % interval on which to run ISAC
end

% handle empty input
unique_units = unique(spikes(:,2));
if isempty(spikes) || numel(unique_units) == 1
  [weights,assembly_sizes] = deal(NaN);
  return
end

% restrict spikes to requested intervals, collapsing holes in time
for i = 1 : size(opt.restrict,1)
  spikes = Restrict(spikes,opt.restrict(i,:));
end

% detect assemblies
weights = SimSpikeAssemblies(spikes,window,2.57).';
assembly_sizes = sum(weights,1);