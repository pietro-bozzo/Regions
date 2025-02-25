function [FR,time] = firingRate(this,state,regs,opt)
% firingRate Get population firing rates via gaussian smoothing of spike counts
%
% arguments:
%     state      string = 'all', behavioral state
%     regs       (n_regs,1) double = [], brain regions, default is all regions
%
% name-value arguments:
%     window     double = 0.05, time bin for firing rate computation
%     smooth     double = 2, gaussian kernel std in number of samples
%     nan_pad    logical = false, if true, append NaNs at the end of every state interval (useful for plotting)
%
% output:
%     FR         (n_times,n_regs) double, firing rate at every time step
%     time       (n_times,1) double, time steps

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  this (1,1) regions
  state (1,1) string = 'all'
  regs (:,1) double = []
  opt.window (1,1) double {mustBePositive} = 0.05
  opt.smooth (1,1) double {mustBeNonnegative} = 2
  opt.nan_pad (1,1) {mustBeLogical} = false
end

if ~this.hasSpikes()
  error('firingRate:missingSpikes','Spikes have not been loaded.')
end

% find requested state and regions
[s_index,r_indeces,state] = this.indeces(state,regs);

% get firing rate of requested regions
event_stamps = vertcat(this.phase_stamps{:});
FR = [];
time = [];
for interval = event_stamps.'
  event_FR = []; % all firing rates for this event
  freq = []; % store temporarily region firing rate and its time for this event
  for r = r_indeces
    spike_times = this.regions_array(r).spikes(:,1);
    if ~isempty(spike_times)
      freq = Frequency(spike_times,'limits',[interval(1),interval(2)],'binSize',opt.window,'smooth',opt.smooth);
      event_FR = inhomogeneousHorzcat(event_FR,freq(:,2));
    end
  end
  FR = [FR;event_FR];
  time = [time;freq(1:size(event_FR,1),1);];
end

%all_spikes = this.spikes(state,regs);

% get firing rate of requested regions OLD
% FR = [];
% for r = r_indeces
%   spike_times = this.regions_array(r).spikes(:,1);
%   if ~isempty(spike_times)
%     freq = Frequency(spike_times,'limits',[all_spikes(1,1),all_spikes(end,1)],'binSize',opt.window,'smooth',opt.smooth);
%     FR = inhomogeneousHorzcat(FR,freq(:,2));
%     % EXTRA CODE TO CHECK CONSISTENCY OF Frequency time, TO REMOVE
%     if exist('time','var') % TEMP check TO SEE IF ALGO IS CONSISTENT
%       min_len = min(size(time,1),size(freq,1));
%       if any(time(1:min_len) - freq(1:min_len,1) > 1e-5)
%         warning('Inconsistent time')
%       end
%     end
%     % END OF EXTRA CODE
%     time = freq(1:size(FR,1),1);
%   end
% end

% filter by state
if state ~= "all"
  ind = false(size(time)); % ind(i) = 1 iff time(i) is in state
  nan_ind = [];
  for interval = this.state_stamps{s_index}.'
    new_ind = time > interval(1) & time < interval(2);
    if any(new_ind)
      ind = ind | new_ind;
      nan_ind(end+1) = find(new_ind,1,'last') + 1; % nan_ind(j) is i : at time(i) state ends
    end   
  end
  if opt.nan_pad % add NaNs at the end of each valid time interval to allow plotting
    ind(nan_ind) = true;
    FR(nan_ind,:) = NaN;
  end
  % keep only state traces
  FR = FR(ind,:);
  time = time(ind,:);
elseif opt.nan_pad
  FR = [FR;nan(1,size(FR,2))];
end

end

function c = inhomogeneousHorzcat(a,b)
  if isempty(a)
    c = b;
  elseif isempty(b)
    c = a ;
  else
    min_len = min(size(a,1),size(b,1));
    c = [a(1:min_len,:),b(1:min_len,:)];
  end
end