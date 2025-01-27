function saveSpikes(this,opt)
% saveSpikes Save spikes per region to .txt file in session folder

arguments
  this (1,1) regions
  opt.folder (1,1) string = "" % subfoler of basename/Pietro, default is Data/Units
end

if isempty(this.ids)
  error('saveNeurons:missingSpikes','Spikes have not been loaded.')
end

% set default value
if opt.folder == ""
  opt.folder = 'Data/Units';
end

% check or make data folder
path = append(this.session_path,'/',opt.folder);
if ~isfolder(path)
  mkdir(path)
end

for i = 1 : numel(this.ids)
  % save units
  file_name = append(path,'/units.',num2str(this.ids(i)));
  writematrix(this.regions_array(i).neurons,file_name,FileType='text');
  % save spikes
  file_name = append(path,'/spikes.',num2str(this.ids(i)));
  writematrix(this.regions_array(i).spikes,file_name,FileType='text');
end