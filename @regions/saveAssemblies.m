function saveAssemblies(this,opt)
% saveAssemblies Save assemblies activations to .txt file in session folder

arguments
  this (1,1) regions
  opt.folder (1,1) string = "" % subfoler of basename/Pietro, default is Data/<method>Asmb, e.g., Data/ICAAsmb
  opt.regs (:,1) double = []
end

assert(this.hasAssemblies(),'saveAssemblies:missingAssemblies','Assemblies have not been computed.')

% set default value
if opt.folder == ""
  opt.folder = append('Data/',this.asmb_method,'Asmb');
end

% find requested regions
[s_index,~,~,regs] = this.indeces('all',opt.regs);

% check or make data folder
path = append(this.session_path,'/',opt.folder);
if ~isfolder(path)
  mkdir(path)
end

% save assembly weights COULD BE A SINGLE FILE
weights_path = append(path,'/Weights');
if ~isfolder(weights_path)
  mkdir(weights_path)
end
file_name = append(weights_path,'/asmb_w',num2str(this.asmb_window*1000),'_',this.asmb_event,'_',this.asmb_state);
for r = this.regions_array.'
  writematrix(r.asmb_weights,append(file_name,'.',num2str(r.id),'.wei'),FileType='text');
end

% save anatomical position of assemblies
file_name = append(path,'/asmb_w',num2str(this.asmb_window*1000),'_',this.asmb_event,'_',this.asmb_state,'.anat');
anatomy = [regs,this.asmbAnatomy(regs)];
anatomy(isnan(anatomy)) = -1; % convert NaN to -1 to make it readable for numpy
writematrix(anatomy,file_name,FileType='text');

% save assemblies activations
file_name = append(path,'/asmb_w',num2str(this.asmb_window*1000),'_',this.asmb_event,'_',this.asmb_state,'.act');
activations = this.asmbActivations(this.states(s_index),regs);
activations(isnan(activations)) = -1; % convert NaN to -1 to make it readable for numpy
writematrix(activations,file_name,FileType='text');