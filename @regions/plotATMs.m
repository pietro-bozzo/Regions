function plotATMs(this,opt)
% plotATMs Plot avalanche transition matrices computed using ICs of various regions

arguments
  this (1,1) regions
  opt.states (:,1) string = []
  opt.indeces (:,1) double = []
  opt.clim (2,1) double = [0,0.2]
  opt.save (1,1) {mustBeLogical} = false
  opt.show (1,1) {mustBeLogical} = false
end

% find requested states and regions
[i_indeces,~,opt.states] = this.getIndeces(opt.states);
% plot figure
s = 1;
for i = i_indeces
  brain = this.brain_array(i);
  if isempty(opt.indeces)
    opt.indeces = 1 : numel(brain.ATMs);
  end
  for j = opt.indeces
    fig = figure(Name='ATM',NumberTitle='off',Position=get(0,'Screensize')); colormap('hot')
    t = tiledlayout(2,3,TileSpacing='Compact'); main_ax = nexttile(1,[2,2]); avrg_ax = nexttile(3,[1,1]);
    xlabel(main_ax,'regions, t',FontSize=14);
    ylabel(main_ax,'regions, t + 1',FontSize=14);
    % create region labels
    main_ticks = 0.5;
    main_labels = "";
    avrg_labels = [];
    for k = 1 : numel(brain.IC_weights)
      main_ticks = [main_ticks;main_ticks(end)+size(brain.IC_weights{k},2)/2;main_ticks(end)+ ...
        size(brain.IC_weights{k},2)];
      main_labels = [main_labels,regionID2Acr(this.ids(k)),""];
      avrg_labels = [avrg_labels,regionID2Acr(this.ids(k))];
    end
    % average ATM
    indeces = main_ticks(1:2:end) + 0.5;
    avrg_ATM = zeros(numel(brain.IC_weights));
    for k = 1 : numel(brain.IC_weights)
      for l = 1 : numel(brain.IC_weights)
        % old implementation: plain average
        % avrg_ATM(k,l) = nanmean(brain.ATMs{j}(indeces(k):indeces(k+1)-1,indeces(l):indeces(l+1)-1),"all");
        % new implementation: average the biggest elements
        quantile = 0.25; % fraction of values to average
        values = brain.ATMs{j}(indeces(k):indeces(k+1)-1,indeces(l):indeces(l+1)-1);
        values = sort(reshape(values,1,[]),'descend');
        avrg_ATM(k,l) = mean(values(1:round(quantile*numel(values))));
      end
    end
    % plot matrices
    h = imagesc(main_ax,brain.ATMs{j}); set(h,'AlphaData',~isnan(brain.ATMs{j})); colorbar(main_ax)
    h = imagesc(avrg_ax,avrg_ATM); set(h,'AlphaData',~isnan(avrg_ATM)); colorbar(avrg_ax)
    % add lineas separating regions
    for k = 2 : numel(indeces) - 1
      line(main_ax,[indeces(k)-0.5,indeces(k)-0.5],[0.5,indeces(end)-0.5],Color=[1,1,1]);
      line(main_ax,[0.5,indeces(end)-0.5],[indeces(k)-0.5,indeces(k)-0.5],Color=[1,1,1]);
    end
    % adjust plots
    set(main_ax,TickDir='out',XLim=[0.5,size(brain.ATMs{j},1)+0.5],YLim=[0.5,size(brain.ATMs{j},2)+0.5], ...
      YDir='normal',XTick=main_ticks,YTick=main_ticks,XTickLabel=main_labels,YTickLabel=main_labels, ...
      CLim=opt.clim,Box='off',PlotBoxAspectRatio=[1,1,1])
    set(avrg_ax,TickDir='out',XLim=[0.5,numel(brain.IC_weights)+0.5],YLim=[0.5,numel(brain.IC_weights)+ ...
      0.5],YDir='normal',XTick=1:numel(brain.IC_weights),XTickLabel=avrg_labels,YTickLabel=avrg_labels, ...
      XTickLabelRotation=30,Box='off',PlotBoxAspectRatio=[1,1,1])
    % create title
    stamps = brain.ATM_stamps{j};
    if isempty(stamps)
      stamps = 'None';
    else
      stamps = append('[',strjoin(string([stamps(1,1),stamps(end,2)]),','),']');
    end
    title(t,append('Avalanche transition matrix for ',this.basename,', state: ',opt.states(s), ...
      ', window: ',string(brain.IC_window),', interval: ',stamps),FontSize=17,FontWeight='Normal');
    if opt.save
      %saveas(fig,append(this.results_path,'/ATM.',string(this.regions_array(1,i).id), ...
      %  '.svg'),'svg') IMPLEMENT?
    end
    if ~opt.show
      if ~opt.save
        warning('Both options ''save'' and ''show'' were not selected.')
      end
      close(fig)
    end
  end
  s = s + 1;
end