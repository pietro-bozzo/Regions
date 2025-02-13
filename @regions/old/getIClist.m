function list = getIClist(this,state)
% getIClist Get array of number of ICs per region, computed over a given state

arguments
  this (1,1) regions
  state (1,1) string
end

state_index = this.getIndeces(state);
list = this.brain_array(state_index).getIClist();