function times = getAvalTimes(this,opt) % SHOULD ERROR IF NO avals OR no DT
% getAvalTimes Get avalanche initiation times

arguments
  this (1,1) brain
  opt.full (1,1) {mustBeLogical} = false % if true, get also times without aval
end

if opt.full
  times = this.IC_window/2 : this.IC_window : (this.aval_indeces(end)-0.5)*this.IC_bin_size;
else
  times = this.aval_indeces(:,1) * this.IC_window - this.IC_window/2;
end