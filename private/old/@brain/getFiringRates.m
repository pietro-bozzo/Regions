function rates = getFiringRates(this,opt)
% getFiringRates Get firing rates for each region DEPRECATED

  arguments
    this (1,1) brain
    opt.binarize (1,1) {mustBeLogical} = false
  end

  rates = this.firing_rates;
  if opt.binarize
    rates = abs(zscore(this.firing_rates)) > this.aval_threshold;
  end