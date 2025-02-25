function fig = plotAsmbRaster(this,start,stop,opt)
% plotAsmbRaster Plot activation raster for assemblies

arguments
  this (1,1) regions
  start (1,1) double {mustBeNonnegative}
  stop (1,1) double {mustBeNonnegative}
  opt.states (:,1) string = "all"
  opt.regions (:,1) double = []
  opt.avals (1,1) {mustBeLogical} = false
  opt.aval_thresh (1,1) double {mustBeNonnegative} = 0
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = true
end

% find requested states and regions
[s_indeces,r_indeces,opt.states,opt.regions] = this.indeces(opt.states,opt.regions);

% make figure
fig = figure(Name='raster',NumberTitle='off',Position=get(0,'Screensize')); hold on
title(append('Raster for ',this.printBasename(),', ',this.asmb_method,', w: ',num2str(this.asmb_window),', event: ',this.asmb_event,', state: ',this.asmb_state),FontSize=17,FontWeight='Normal');

% loop over states and regions
ticks = 0.5;
labels = "";
done_ticks = false;
max_stop = stop;
for s = 1 : numel(s_indeces)
  state_activations = [];
  n_asmb_cum = 0;
  for r = r_indeces
    activations = this.asmbActivations(this.states(s_indeces(s)),this.ids(r));
    assemblies = this.regions_array(r).assemblies;
    if ~isempty(assemblies)
      if ~isempty(activations) && ~any(any(isnan(activations)))
        times = activations(:,1);
        if stop <= 0
          stop = -times(end) - 0.001;
          max_stop = max([max_stop,abs(stop)]);
        end
        % keep activations in requested time
        activations = activations(times > start & times < abs(stop),:);
        % relabel assemblies to a contigous {1,...,N} set, preserving unit order
        activations = compactSpikes(activations,assemblies);
        activations(:,2) = activations(:,2) + n_asmb_cum;
        state_activations = [state_activations;activations];
      end
      n_asmb_cum = n_asmb_cum + numel(assemblies);
      % plot avalanches TO IMPLEMENT
      %if opt.avals
      %  if isempty(brain.aval_indeces)
      %    error('plotICRaster:MissingAvalanches','Avalanches haven''t been computed.');
      %  end
      %  aval_intervals = brain.getAvalIntervals(restriction=[start;abs(stop)],threshold=opt.aval_thresh);
      %  plotIntervals(aval_intervals,color=[0.5,0.5,0.5],alpha=0.15,ylim=[0,sum(IClist)])
      %end
      % make y labels
      if ~done_ticks
        ticks = [ticks;(ticks(end)+n_asmb_cum+0.5)/2;n_asmb_cum+0.5];
        labels = [labels;regionID2Acr(this.ids(r));""];
      end
    end
  end
  done_ticks = true;
  % plot activations
  raster(state_activations,'color',myColors(s),'DisplayName',this.states(s_indeces(s)))
end

% create y labels ADAPT TO ONLY HAVE SOME REGIONS
% valid = all(~isnan(anatomy),2); % keep only regions with assemblies
% [ticks,ind] = sortrows(anatomy(valid,:));
% ticks = [(ticks(:,1) + ticks(:,2)) / 2,ticks(:,2)+0.5].';
% ticks = [0.5;ticks(:)];
% regs = opt.regions(valid);
% labels = [repmat("",size(regs)),regionID2Acr(regs(ind))].';
% labels = [labels(:);""];

% adjust plot
if max_stop == start % to prevent error in XLim=[start;max_stop] when no regions have assemblies
  max_stop = start + 1;
end
if ticks(end) == 0.5 % to prevent error in YLim=[0.5,ticks(end)] when no regions have assemblies
  ticks(end) = 1;
end
adjustAxes(gca,'XLim',[start;max_stop],'YLim',[0.5,ticks(end)],'YTick',ticks,'YTickLabel',labels)
xlabel('time (s)',FontSize=14);
ylabel('assemblies',FontSize=14);
legend()

if opt.save
  %saveas(fig,append(this.results_path,'/raster.',string(this.ids(i)),'.svg'),'svg')
end
if ~opt.show
  close(fig)
end


  % % reorder lines according to delay from time instant OLD CODE
  % t = start + (stop-start)/5;
  % unique_ICs = unique(ICs);
  % IC_delays = zeros(size(unique_ICs));
  % for i = 1 : numel(unique_ICs)
  %   IC_times = times_sec(ICs==unique_ICs(i));
  %   delays = IC_times(IC_times>t);
  %   IC_delays(i) = delays(1) - t;
  % end
  % [~,ind] = sort(IC_delays);
  % sorted_ICs = zeros(size(ICs));
  % for i = 1 : numel(ind)
  %   sorted_ICs(ICs==ind(i)) = i;
  % end
  % ICs = sorted_ICs;