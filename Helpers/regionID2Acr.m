function acr = regionID2Acr(id,file)
% regionID2Acr Get region acronym(s) from id(s), optionally using a legend stored in file
%
% arguments:
%     id      double or string, ids to convert
%     file    string = '', file containing legend TO IMPLEMENT

arguments
  id
  file (1,1) string = ""
end

if ischar(id) || isstring(id)
  id = str2double(id);
end

% if isempty file then: ALSO THIS SHOULD DEAL WITH RIGHT LEFT AND REGION SEPRATELY
legend = dictionary([-1,0,1,2,10,11,12,20,21,22,30,31,32,40,41,42,50,51,52,70,71,72,80,81,82,90,91,92], ...
  ["Unknown id: ","undefined mPFC","l undefined mPFC","r undefined mPFC","vmPFC","l vmPFC","r vmPFC","dmPFC","l dmPFC","r dmPFC","dHPC","l dHPC","r dHPC","vHPC", ...
   "l vHPC","r vHPC","AMY","l AMY","r AMY","REU","l REU","r REU","TH","l TH","r TH","V1","l V1","r V1"]);

unknown_ind = ~ismember(id,legend.keys);
unknown_ids = string(id(unknown_ind));
id(unknown_ind) = -1;
acr = legend(id);
acr(unknown_ind) = acr(unknown_ind) + unknown_ids;