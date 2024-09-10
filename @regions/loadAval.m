function this = loadAval(this,opt) % NOT ROBUST TO SWITCHING STATE ORDER
% loadAval Load previously computed spike avalanches

arguments
  this (1,1) regions
  opt.spike_dt (1,1) double {mustBePositive} = 0.02
  opt.threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(opt.threshold,1)} = 0
end

% read log file
extension = append('.',num2str(opt.spike_dt*100000));
if opt.threshold ~= 0
  extension = append(extension,'.',num2str(opt.threshold*10));
end
if this.phase ~= "all"
  extension = append('.',this.phase,extension);
end
file_name = append(this.results_path,'/',this.basename,extension,'.aval_log');
fileID = fopen(file_name);
if fileID == -1
  err.message = append('Unable to open ',file_name,'.');
  err.identifier = 'loadAval:FileNotFound';
  error(err);
end
states = split(string(fgetl(fileID)));
ids = double(split(string(fgetl(fileID))));
if isempty(this.ids)
  this.ids = ids;
end
n_neurons = double(split(string(fgetl(fileID))));
n = double(split(string(fgetl(fileID))));
n = [0;cumsum(n)];
fclose(fileID);
% read avalanches
file_name = append(this.results_path,'/',this.basename,extension,'.aval');
aval = readmatrix(file_name,FileType='text');
% store avalanches
[i_indeces,j_indeces] = this.getIndeces(states,ids);
fill = isempty(this.regions_array);
k = 1;
for j = j_indeces
  for i = i_indeces % NOT ROBUST TO SWITCHING STATE ORDER
    if fill % populate regions-array
      this.regions_array(i,j) = region(this.basename,this.session_path,this.ids(j), ...
        state=this.states(i),n_neurons=n_neurons(k));
    end
    this.regions_array(i,j) = this.regions_array(i,j).setAvalanches(opt.spike_dt,opt.threshold, ...
      aval(n(k)+1:n(k+1),1:2),aval(n(k)+1:n(k+1),3));
    k = k + 1;
  end
end