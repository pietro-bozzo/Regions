function times = getAvalTimes(this,opt) % SHOULD ERROR IF NO avals OR no DT
% getAvalTimes Get avalanche initiation times

arguments
  this (1,1) brain
  opt.full (1,1) {mustBeLogical} = false % if true, get also times without aval
end

if opt.full
  times = this.rate_dt/2 : this.rate_dt : (this.aval_indeces(end)-0.5)*this.rate_dt;
else
  times = this.aval_indeces(:,1) * this.rate_dt - this.rate_dt/2;
end