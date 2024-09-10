function saveAval(this)
% saveAval Save spike avalanches

arguments
  this (1,1) regions
end

% pool avalanches 
n = strings().empty();
sizes = [];
durations = [];
indeces = [];
n_neurons = [];
for i = 1 : numel(this.regions_array) % N NEURON IS NEEDLESSLY REPEATED
  s = this.regions_array(i).getAvalSizes();
  n = [n;string(numel(s))]; % WHY string?? CAN DO SAME AS OTHERS
  sizes = [sizes;s];
  indeces = [indeces;this.regions_array(i).getAvalIndeces()];
  n_neurons = [n_neurons;this.regions_array(i).getNNeurons()];
end
% create log file with states, regions ids, n of neurons per region, and n of avals
extension = append('.',num2str(this.regions_array(1).getSpikeDt()*100000));
if this.regions_array(1).getAvalThreshold() ~= 0
  extension = append(extension,'.',num2str(this.regions_array(1).getAvalThreshold()*10));
end
if this.phase ~= "all"
  extension = append('.',this.phase,extension);
end
file_name = append(this.results_path,'/',this.basename,extension,'.aval_log');
if ~isfile(file_name)
  writematrix([],file_name,FileType='text');
end
fileID = fopen(file_name,'w');
fprintf(fileID,append(strjoin(this.states),newline));
fprintf(fileID,append(strjoin(string(this.ids)),newline));
fprintf(fileID,append(strjoin(string(n_neurons)),newline));
fprintf(fileID,append(strjoin(n),newline));
fclose(fileID);
% save avalanches
file_name = append(this.results_path,'/',this.basename,extension,'.aval');
writematrix([indeces,sizes],file_name,FileType='text');