function [state_indeces,region_indeces,states,regs] = getIndeces(this,states,regs,opt)
% getIndeces Get indeces of input states and regions in regions_array

arguments
  this (1,1) regions
  states (:,1) string = []
  regs (:,1) double = [] % IMPLEMENT POSSIBILITY TO GIVE ACR?
  opt.brain (1,1) {mustBeLogical} = true
  opt.strict (1,1) {mustBeLogical} = true
end

% find requested states
if isempty(states)
  state_indeces = 1 : numel(this.states);
  states = this.states;
else
  state_indeces = [];
  for state = states.'
    index = find(this.states==state);
    if isempty(index)
      if opt.strict
        error(append('Unrecognized state: ',state))
      else
        warning(append('Unrecognized state: ',state))
      end
    end
    state_indeces = [state_indeces,index];
  end
end
% find requested regions
if ~opt.brain && any(regs==0)
  warning('Region 0 was requested but excluded.')
end
if isempty(regs)
  region_indeces = 1 : numel(this.ids);
  regs = this.ids;
else
  region_indeces = [];
  for reg = regs.'
    index = find(this.ids==reg);
    if isempty(index)
      if opt.strict
        error(append('Unrecognized region: ',string(reg)))
      else
        warning(append('Unrecognized region: ',string(reg)))
      end
    end
    region_indeces = [region_indeces,index];
  end
end
if ~opt.brain
  region_indeces = region_indeces(regs~=0);
  regs = regs(regs~=0);
end