function [firing_rates,time] = unitFiringRates(this,state,regs,opt)
% unitFiringRates Get unit firing rates via gaussian smoothing of spike counts
%
% arguments:
%     state           string = 'all', behavioral state
%     regs            (n_regs,1) = [], brain regions, default is all regions
%
% name-value arguments:
%     window          double = 0.05, time bin for firing rate computation
%     step            double = 1, windows will overlap of window/step, default is no overlap
%     smooth          double = 1, gaussian kernel std in number of samples, default is no smoothing
%     zscore          logical = false, if true, zscore each neuron's activity
%     nan_pad         logical = false, if true, append NaNs at the end of every state interval (useful for plotting)
%
% output:
%     firing_rates    (n_times,n_regs) double, firing rate at every time step
%     time            (n_times,1) double, time steps

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  state (1,1) string = 'all'
  regs (:,1) string = []
  opt.window (1,1) {mustBeNumeric,mustBePositive} = 0.05
  opt.step (1,1) {mustBeNumeric,mustBeInteger,mustBePositive} = 1
  opt.smooth (1,1) {mustBeNumeric,mustBePositive} = 1
  opt.zscore (1,1) {mustBeLogical} = false
  opt.nan_pad (1,1) {mustBeLogical} = false
end

if ~this.hasSpikes()
  error('unitFiringRates:missingSpikes','Spikes have not been loaded')
end

% find state and regions
try
  [state,regs,s_index] = this.arrayInd(state,regs);
catch ME
  throw(ME)
end

% firing rate per unit
% restrict time in loaded events
event_stamps = ConsolidateIntervals(this.eventIntervals,'epsilon',0.0001);
spikes = this.spikes('all',regs);
neurons = this.units(regs);
firing_rates = [];
time = [];
for interval = event_stamps.'
  FR = nan(floor(diff(interval)/opt.window)*opt.step,numel(neurons));
  for n = 1 : numel(neurons)
    % smooth / 5 to compensate for internal behavior of Frequency
    f = Frequency(spikes(spikes(:,2)==neurons(n),1),'limits',[interval(1),interval(2)],'binSize',opt.window,'step',opt.step,'smooth',opt.smooth/5);
    FR(:,n) = f(:,2);
  end
  firing_rates = [firing_rates;FR];
  if ~isempty(FR)
    time = [time;f(:,1)];
  end
end

% filter by state
if state ~= "all"
  ind = false(size(time)); % ind(i) = 1 iff time(i) is in state
  nan_ind = [];
  for interval = this.state.times{s_index}.'
    new_ind = time > interval(1) & time < interval(2);
    if any(new_ind)
      ind = ind | new_ind;
      nan_ind(end+1) = find(new_ind,1,'last') + 1; % nan_ind(j) is i : at time(i) state ends
    end   
  end
  if opt.nan_pad % add NaNs at the end of each valid time interval to allow plotting
    ind(nan_ind) = true;
    firing_rates(nan_ind,:) = NaN;
    if nan_ind(end) >= numel(time) % if necessary, extend time
      time(end+1) = time(end) + time(end) - time(end-1);
    end
  end
  % keep only state traces
  firing_rates = firing_rates(ind,:);
  time = time(ind,:);
elseif opt.nan_pad
  firing_rates = [firing_rates;nan(1,size(firing_rates,2))];
end

if opt.zscore
  firing_rates = zscore(firing_rates);
end