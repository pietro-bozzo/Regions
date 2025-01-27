function this = computeICA(this,window,opt)
% computeICA Perform Indipendent Component Analysis to detect assemblies using spiking activity from each region

arguments
  this (1,1) regions
  window (1,1) double {mustBePositive} = 0.015
  opt.event (1,1) string = "all" % allows to filter spikes of a specific event for assembly detection
  opt.state (1,1) string = "all" % allows to filter spikes of a specific state for assembly detection
  opt.restrict (:,2) double {mustBeNonnegative} = [] % intervals on which to perform ICA
end

num_ids = numel(this.ids);

% set up wait bar
%f = waitbar(0,'Please wait...');
%total_iterations = num_ids;
%updateWaitBar(f, total_iterations, true);
%q = parallel.pool.DataQueue;
%afterEach(q, @(k) updateWaitBar(f, total_iterations, false));

IC_weights = cell(num_ids,1);
IC_activations = cell(num_ids,1);

% get time stamps to filter spikes over which to perform ICA
% restrict over event
event_stamps = []; % needed for parfor to work, default uses all spikes
if opt.event ~= "all"
  if opt.event == "task"
    event_stamps = this.phase_stamps{2};
  else
    if ~any(this.phases==opt.event)
      error('comnputeICA:MissingEvent',append('Unable to find event ',opt.IC_event,'.'))
    end
    event_stamps = this.phase_stamps{this.phases==opt.event};
  end
end
% restrict over state
state_stamps = [];
if opt.state ~= "all"
  if ~any(this.states==opt.state)
    error('comnputeICA:MissingState',append('Unable to find state ',opt.state,'.'))
  end
  state_stamps = this.state_stamps{this.states==opt.state};
end

regions_array = this.regions_array(:); % needed to avoid passing the whole regions structure to the parfor

parfor k = 1 : num_ids
  region = regions_array(k);
  % restrict spikes for assembly detetction
  ICA_spikes = region.spikes;
  if opt.event ~= "all"
    ICA_spikes = Restrict(ICA_spikes,event_stamps,'shift','off');
  end
  if opt.state ~= "all"
    ICA_spikes = Restrict(ICA_spikes,state_stamps,'shift','off');
  end
  ICA_spikes = compactSpikes(ICA_spikes,region.neurons); % compact spikes to have correct weights size
  weights = ICAssemblies(ICA_spikes,window,restrict=opt.restrict,units=region.neurons); % detect assemblies over requested time
  % compute assemblies' activations over all spikes
  spikes = compactSpikes(region.spikes,region.neurons);
  IC_activations{k} = ICActivations(spikes,weights,window); % compute activations over all time
  IC_weights{k} = weights;
  %send(q, k);
end
%close(f);

IC_n_cumul = 0;
for i = 1 : num_ids
  % give unique ids to assemblies
  assemblies = (1 : size(IC_weights{i},2)).' + IC_n_cumul;
  if ~isempty(IC_activations{i})
    IC_activations{i}(:,2) = IC_activations{i}(:,2) + IC_n_cumul;
  end
  this.regions_array(i) = this.regions_array(i).setAssemblies(assemblies,IC_weights{i},IC_activations{i});
  IC_n_cumul = IC_n_cumul + size(IC_weights{i},2);
end

% store analysis parameters
this.asmb_method = 'ICA';
this.asmb_state = opt.state;
this.asmb_event = opt.event;
this.asmb_window = window;
end

% OLD CODE
% function ICS = homogeneousICS(IC_activity) % DEPRECATED
%     n = size(IC_activity, 2);
%     lens = cellfun(@(x) size(x, 1), IC_activity);
%     lens = lens(lens > 1);
%     if isempty(lens)
%       ICS = NaN(2,n);
%       return
%     end
%     len = min(lens);
%     ICS = [];
%     for i = 1:n
%         ic = IC_activity{i};
%         if any(any(isnan(ic)))
%             ics = NaN(len, 1);
%         else
%             ics = ic(1:len,:);
%         end
%         ICS = [ICS, ics];
%     end
% end

function spikes = mergeSpikeLists(lists,n_units)
  n_unit_cum = [0;cumsum(n_units)];
  spikes = [];
  for i = 1 : numel(lists) % CAN BE VECTORIZED USING INDEXING?
    spike_list = lists{i};
    if ~isempty(spike_list)
      if max(spike_list(:,2)) > n_unit_cum(i+1)
        error('Number of units doesn''t correspond to spike lists.')
      end
      spike_list(:,2) = spike_list(:,2) + n_unit_cum(i);
      spikes = [spikes;spike_list];
    end
  end
  spikes = sortrows(spikes);
end

function updateWaitBar(f, total_iterations, reset)
    persistent iter;
    if isempty(iter) || reset
        iter = 0;
    else
        iter = iter + 1;
    end
    waitbar(iter / total_iterations, f, sprintf('Computing (%d/%d)', iter, total_iterations)); % Update waitbar; change 1000 to N if necessary
end