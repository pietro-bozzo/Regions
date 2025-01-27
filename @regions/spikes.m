function spikes = spikes(this,state,regs)
% spikes Get spike list of requested regions in a state

arguments
  this (1,1) regions
  state (1,1) string = "all"
  regs (:,1) double = [] % IMPLEMENT POSSIBILITY TO GIVE ACR?
end

if ~this.hasSpikes()
  error('asmbActivations:missingSpikes','Spikes have not been loaded.')
end

% find requested state and regions
[s_index,r_indeces] = this.indeces(state,regs);

% get activations of requested reagions
spikes = [];
for r = r_indeces
  spikes = [spikes;this.regions_array(r).spikes];
end

% sort by time
spikes = sortrows(spikes);

% filter by state
if state ~= "all"
  spikes = Restrict(spikes,this.state_stamps{s_index},'shift','off');
end