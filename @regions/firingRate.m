function [FR,time] = firingRate(this,state,regs,opt)
% firingRate Get population firing rate of requested regions in a state

arguments
  this (1,1) regions
  state (1,1) string = "all"
  regs (:,1) double = []
  opt.smooth (1,1) double {mustBeNonnegative} = 2
  opt.nan_pad (1,1) {mustBeLogical} = false
end

if ~this.hasSpikes()
  error('asmbActivations:missingSpikes','Spikes have not been loaded.')
end

% find requested state and regions
[s_index,r_indeces] = this.indeces(state,regs);

% get firing rate of requested regions
FR = [];
for r = r_indeces
  spike_times = this.regions_array(r).spikes(:,1);
  % DOC FOR Smooth OF 1D DATA SHOULD BE: 2nd arg CAN BE [kernel_std] OR [kernel_std,kernel_size]
  freq = myFrequency(spike_times,'limits',[0,spike_times(end)],'smooth',opt.smooth);
  FR = inhomogeneousHorzcat(FR,freq(:,2));
  % EXTRA CODE TO CHECK CONSISTENCY OF Frequency time, TO REMOVE
  if exist('time','var') % TEMP check TO SEE IF ALGO IS CONSISTENT
    min_len = min(size(time,1),size(freq,1));
    if all(time(1:min_len) ~= freq(1:min_len,1))
      warning('Inconsistent time')
    end
  end
  time = freq(1:size(FR,1),1);
end

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