function saveICA(this,path,regions)
% saveICA Save ICA assemblies activations to .txt file in provided path

arguments
  this (1,1) brain
  path (1,1) string % path to folder to save file to
  regions (:,1) double % regions assemblies belong to
end

% save assemblies activations
file_name = append(path,'/ICA_activ_',this.state,'_',num2str(this.IC_window*1000));
writematrix(this.ICs_activations,file_name,FileType='text');
% save assemblies anatomical positions
file_name = append(path,'/ICA_anat_',this.state,'_',num2str(this.IC_window*1000));
writematrix([regions,cellfun(@(x) size(x, 2), this.IC_weights)],file_name,FileType='text');