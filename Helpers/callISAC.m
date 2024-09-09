function [assemblies,assembly_sizes] = callISAC(spikes,opt)
% callISAC Call ISAC to detect cell assemblies
%
% arguments:
% spikes (:,2) double                                 matrix having sorted time stamps as first column and units as second
% time_window (1,1) double {mustBePositive} = 0.03    time window to detect neuron coactivations

arguments
    spikes (:,2) double
    opt.time_window (1,1) double {mustBePositive} = 0.03
end

% relabel units to a {1,...,N} set
[~,~,spikes(:,2)] = unique(spikes(:,2),'rows');
% detect assemblies
if max(spikes(:,2)) > 2
    assemblies = SimSpikeAssemblies(spikes,opt.time_window);
else
    % not enough neurons
    assemblies = zeros(0,max(spikes(:,2)));
end
assembly_sizes = sum(assemblies,2);