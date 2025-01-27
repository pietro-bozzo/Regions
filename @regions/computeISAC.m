function this = computeISAC(this,window,opt)
% computeICA Call ISAC to detect assemblies using spiking activity from each region

arguments
  this (1,1) regions
  window (1,1) double {mustBePositive} = 0.015
  opt.event (1,1) string = "all" % allows to filter spikes of a specific event for assembly detection
  opt.state (1,1) string = "all" % allows to filter spikes of a specific state for assembly detection
  opt.restrict (:,2) double {mustBeNonnegative} = [] % intervals on which to perform ICA
end

% get time stamps to filter spikes over which to perform ICA
% restrict over event
if opt.event ~= "all"
  if opt.event == "task"
    event_stamps = this.phase_stamps{2};
  else
    if ~any(this.phases==opt.event)
      error('comnputeISAC:MissingEvent',append('Unable to find event ',opt.IC_event,'.'))
    end
    event_stamps = this.phase_stamps{this.phases==opt.event};
  end
end
% restrict over state
if opt.state ~= "all"
  if ~any(this.states==opt.state)
    error('comnputeISAC:MissingState',append('Unable to find state ',opt.state,'.'))
  end
  state_stamps = this.state_stamps{this.states==opt.state};
end

asmb_n_cumul = 0;
for i = 1 : numel(this.ids)
  region = this.regions_array(i);
  % restrict spikes for assembly detetction
  ISAC_spikes = region.spikes;
  if opt.event ~= "all"
    ISAC_spikes = Restrict(ISAC_spikes,event_stamps,'shift','off');
  end
  if opt.state ~= "all"
    ISAC_spikes = Restrict(ISAC_spikes,state_stamps,'shift','off');
  end
  ISAC_spikes = compactSpikes(ISAC_spikes,region.neurons); % compact spikes to have correct weights size
  weights = callISAC(ISAC_spikes,window,restrict=opt.restrict);
  assemblies = (1 : size(weights,2)).' + asmb_n_cumul; % give unique ids to assemblies
  % compute assemblies' activations over all spikes
  spikes = compactSpikes(region.spikes,region.neurons);
  activations = ICActivations(spikes,weights,window);
  if ~isempty(activations)
    activations(:,2) = activations(:,2) + asmb_n_cumul; % give unique ids to assemblies
  end
  this.regions_array(i) = this.regions_array(i).setAssemblies(assemblies,weights,activations);
  asmb_n_cumul = asmb_n_cumul + size(weights,2); % update cumulative number of assemblies
end

% store analysis parameters
this.asmb_method = 'ISAC';
this.asmb_state = opt.state;
this.asmb_event = opt.event;
this.asmb_window = window;