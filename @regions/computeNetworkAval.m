function this = computeNetworkAval(this,opt)
% computeNetworkAval Compute avalanches using IC activity from each region

arguments
  this (1,1) regions
  opt.dt (1,1) double {mustBePositive} = 0.05
  opt.window (1,1) double {mustBePositive} = 0.08
  opt.threshold (1,1) double {mustBeNonnegative} = 2
  opt.save (1,1) {mustBeLogical} = false % SAVE AVALS, TO IMPLEMENT (MAYBE)
end

for i = 1 : numel(this.states) % set up brain_array
  frs = [];
  neurons = [];
  for j = 1 : numel(this.ids)
    if this.ids(j) ~= 0 % exclude region corresponding to whole brain
      fr = this.regions_array(i,j).getFiringRate(opt.dt,opt.window); % REPLACE FR WITH ICA!!!
      % MAYBE A METHOD TO COPMUTE ICA FOR ALL REGIONS SHOULD BE CALLED
      % BEFORE THIS ONE
      if isempty(frs)
        frs = fr;
      else
        len = min(size(fr,1),size(frs,1));
        frs = [frs(1:len,:),fr(1:len)];
      end
      neurons = [neurons;this.regions_array(i,j).getNeurons];
    end
  end
  this.brain_array(i,1) = brain(this.basename,this.session_path,neurons, ...
    opt.dt,opt.window,frs,state=this.states(i));
  this.brain_array(i,1) = this.brain_array(i,1).computeAvalanches(threshold=opt.threshold);
end