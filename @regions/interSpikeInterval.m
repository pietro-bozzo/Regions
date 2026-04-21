function isi = interSpikeInterval(this,regs)
% interSpikeInterval Get average interspike intervals

arguments
  this (1,1) regions
  regs (:,1) string = []
end

if ~this.hasSpikes()
  error('interSpikeInterval:MissingSpikes','Spikes have not been loaded')
end

% find regions
try
  [~,regs] = this.arrayInd([],regs);
catch ME
  throw(ME)
end

isi = zeros(size(regs));
for r = 1 : numel(regs)
  spikes = this.spikes('all',regs(r));
  isi(r) = mean(diff(spikes(:,1)));
end