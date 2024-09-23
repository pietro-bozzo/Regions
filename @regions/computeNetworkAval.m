function this = computeNetworkAval(this,opt)
% computeNetworkAval Compute avalanches using IC activity from each region

arguments
  this (1,1) regions
  opt.window (1,1) double {mustBePositive} = 0.01
  opt.threshold (1,1) double {mustBeNonnegative} = 2
  opt.save (1,1) {mustBeLogical} = false % SAVE ICA, TO IMPLEMENT (MAYBE, IF SLOW)
end

f = waitbar(0,'Please wait...');
num_states = numel(this.states);
num_ids = numel(this.ids);

% Time estimation setup
total_iterations = num_states * num_ids;
iteration_time = NaN(total_iterations,1); % To track each iteration's time

for i = 1:num_states % set up brain_array
  IC_weights = {};
  IC_activity = [];
  k = 1;
  first = true;
  for j = 1:num_ids
    iter = (i-1) * num_ids + j; % Current iteration number
    
    % Time tracking for iteration
    if iter > 1
      iteration_time(iter) = toc(previous); % Record time for current iteration
      previous = tic;
    else
        previous = tic;
    end
    
    % Calculate estimated remaining time and iterations per second
    if iter > 1
      avg_iter_time = mean(iteration_time(max(2, iter-4):iter)); % Average time per iteration
      remaining_time = (total_iterations - iter) * avg_iter_time;
      waitbar((iter-1)/total_iterations, f, ...
        sprintf('Computing (%.2f s/it, %d/%d, ~ %.2f s)', ...
        avg_iter_time, iter, total_iterations, remaining_time));
    end
    
    if this.ids(j) ~= 0 % exclude region corresponding to whole brain
      spikes = this.regions_array(i,j).spikes;
      [IC_weights{k},~,region_activity,t] = getICActivity(spikes,windowsize=opt.window);
      if ~first && previous_t ~= t(1) % check that ICA produces consistent time
        warning('IC output has non matching time');
      end
      first = false; previous_t = t(1); % store first time point for control
      k = k + 1;
      if isempty(IC_activity)
        IC_activity = region_activity;
      elseif any(any(isnan(region_activity))) % adapt size of NaN region_activity
        IC_activity = [IC_activity,NaN(size(IC_activity,1),1)];
      elseif all(all(isnan(IC_activity))) % adapt size of NaN IC_activity
        IC_activity = [NaN(size(region_activity,1),size(IC_activity,2)),region_activity];
      else % cut end of activity to keep same length in time
        len = min(size(region_activity,1),size(IC_activity,1));
        IC_activity = [IC_activity(1:len,:),region_activity(1:len,:)];
      end
    end
  end
  this.brain_array(i,1) = brain(this.basename,this.session_path,IC_weights,opt.window,IC_activity, ...
    state=this.states(i));
  this.brain_array(i,1) = this.brain_array(i,1).computeAvalanches(threshold=opt.threshold);
end

close(f);
end
