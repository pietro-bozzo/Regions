function this = computeAvalanches(this,opt)
      arguments
        this (1,1) region
        opt.spike_dt (1,1) double {mustBePositive} = 0.01
        opt.threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(opt.threshold,1)} = 0
        opt.dopc = false
        opt.pc = NaN
        opt.var = 0.5
        opt.first = true
        opt.pcPercentile = 10
      end
      if opt.dopc
          this.spike_dt = opt.spike_dt;
          n0 = getSpikesMatrix(this.spikes,windowsize=opt.spike_dt);
          [Z, pc, explained] = reconstructPCSpikesMatrix(n0, pc=opt.pc, var=opt.var, first=opt.first);
          [this.aval_sizes,this.aval_profile,this.aval_indeces, this.aval_timeDependendentSize] = getAvalanchesFromMatrix(Z, percentile=opt.pcPercentile);
          this.npc = pc;
          this.explainedVariance = explained;
      else
      this.spike_dt = opt.spike_dt;
      this.aval_threshold = opt.threshold;
      [this.aval_sizes,this.aval_profile,this.aval_indeces, ~, this.aval_timeDependendentSize] = getAvalanchesFromList( ...
        this.spikes,this.spike_dt,threshold=opt.threshold);
      end
    end