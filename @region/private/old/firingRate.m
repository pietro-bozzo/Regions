function [rate,times] = firingRate(this,step,bin_size,opt)
% OLD FIRING RATE CODE
% getFiringRate Get firing rate as the number of spikes recorded in sliding windows of size bin_size
% separated by intervals of size step, not normalized

      arguments
        this (1,1) region
        step (1,1) double {mustBePositive}
        bin_size (1,1) double {mustBePositive}
        opt.restriction (:,1) double = []
      end
      % SHOULD ERROR IF NO SPIKES OR no DT OR NEUR
      [n,k] = rat(bin_size/step); % approximate bin_size/step as a ratio to identify a discretization window
      times = 0 : bin_size/n : this.spikes(end,1)+bin_size/n; % edges of the discretization
      if ~isempty(opt.restriction)
        times = times(times>=opt.restriction(1) & times<=opt.restriction(2));
      end
      rate = histcounts(this.spikes(:,1),times).';
      rate = movmean(rate,n) * n; % compute number of spikes in every sliding window
      rate = rate(1:k:end); % keep only windows separated by 'step' milliseconds
      times = times(1:k:end).';