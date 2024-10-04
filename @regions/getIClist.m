function list = getIClist(this,state)
% getIClist Get array of number of ICs per region, computed over a given state

arguments
  this (1,1) regions
  state (1,1) string
end

state_index = this.getIndeces(state);
list = [];
for i = 1 : numel(this.brain_array(state_index).IC_weights)
  list = [list;size(this.brain_array(state_index).IC_weights{i},2)];
end
list(list=0) = 1; % set to 1 as there is one column of NaNs when no ICs are detected