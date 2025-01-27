function list = getIClist(this)
% getIClist Get array of number of ICs per region

arguments
  this (1,1) brain
end

list = zeros(size(this.IC_weights));
for i = 1 : numel(this.IC_weights)
  list(i) = size(this.IC_weights{i},2);
end
list(list==0) = 1; % set to 1 as there is one column of NaNs when no ICs are detected WRONG: REMOVE WHEN ICs_activity IS DEPRECATED