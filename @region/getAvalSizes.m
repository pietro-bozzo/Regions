function sizes = getAvalSizes(this,opt)
% getAvalSizes Get sizes of avalanches computed using region spiking data

arguments
  this (1,1) region
  opt.full (1,1) {mustBeLogical} = false % if true, get also zeros for all times without aval
end

if ~any(isnan(this.aval_sizes)) && opt.full
  sizes = zeros(this.aval_indeces(end),1);
  sizes(this.aval_indeces(:,1)) = this.aval_sizes;
else
  sizes = this.aval_sizes;
end