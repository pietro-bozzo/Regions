function this = loadAssemblies(this,method,window,event,state,opt)
% loadAssemblies Load assemblies activations from session folder

arguments
  this (1,1) regions
  method (1,1) string
  window (1,1) double {mustBePositive}
  event (1,1) string
  state (1,1) string
  opt.folder (1,1) string = "" % subfoler of basename/Pietro, default is Data/<method>Asmb, e.g., Data/ICAAsmb
end

% set default value
if opt.folder == ""
  opt.folder = append('Data/',method,'Asmb');
end
path = append(this.session_path,'/',opt.folder);

% prepare file roots
units_file = append(this.session_path,'/Data/Units/units.');
weights_file = append(path,'/Weights/asmb_w',num2str(window*1000),'_',event,'_',state);

% load anatomical position of assemblies ACTUALLY NOT NECESSARY! weights HAVE ALL NEEDED INFO
anatomy_file = append(path,'/asmb_w',num2str(window*1000),'_',event,'_',state,'.anat');
anatomy = readmatrix(anatomy_file,FileType='text');
anatomy(anatomy==-1) = NaN; % convert -1 back to NaN
%anatomy = [regs,this.asmbAnatomy(regs)];

% load assemblies activations
activations_file = append(path,'/asmb_w',num2str(window*1000),'_',event,'_',state,'.act');
activations = readmatrix(activations_file,FileType='text');
activations(activations==-1) = NaN; % convert -1 back to NaN

% load data per region
asmb_n_cumul = 0;
for i = 1 : numel(this.ids)
  % load units
  try
    neurons = readmatrix(append(units_file,num2str(this.ids(i))),FileType='text');
  catch except
    if strcmp(except.identifier,'MATLAB:textio:textio:FileNotFound')
      error('loadAssemblies:MissingUnits','Unable to load units file.')
    end
  end
  % load assembly weights COULD BE A SINGLE FILE
  weights = readmatrix(append(weights_file,'.',num2str(this.ids(i)),'.wei'),FileType='text');
  if isempty(weights)
    weights = zeros(numel(neurons),0); % adjust size of empty weights
  end
  assemblies = (1 : size(weights,2)).' + asmb_n_cumul; % give unique ids to assemblies
  asmb_n_cumul = asmb_n_cumul + size(weights,2);

  % separate activations
  reg_ind = find(anatomy(:,1)==this.ids(i));
  if isempty(reg_ind)
    error('')
  end
  activ = activations(activations(:,2) >= anatomy(reg_ind,2) & activations(:,2) <= anatomy(reg_ind,3),:);
  if isempty(activ)
    activ = [NaN,NaN]; % respect convention for no assemblies
  end
  % instantiate region in regions array SHOULD ACTUALLY BE DONE BY regions, NOT BY loadSPikes NOR loadAssemblies
  this.regions_array(end+1,1) = region(this.ids(i),neurons);
  this.regions_array(end,1) = this.regions_array(end,1).setAssemblies(assemblies,weights,activ);
end

% set analyses parameters
this.asmb_method = method;
this.asmb_window = window;
this.asmb_event = event;
this.asmb_state = state;