function acr = regionID2Acr(id,file)
% getRatNumber Get region acronym(s) from id(s), using conversion stored in file name TO IMPLEMENT, FOR NOW IT IS STATIC DICTIONARY
%
% arguments:
% id (:,1) string           array of ids to convert
% file (1,1) string = ""    file containing legend

arguments
    id (:,1) string
    file (1,1) string = ""
end

% if isempty file then: ALSO THI SHOULD DEAL WITH RIGHT LEFT AND REGION SEPRATELY
legend = dictionary(["0","00","1","01","2","02","11","12","21","22","31","32","41","42","51","52","71","72","81","82","91","92"], ...
    ["whole brain","whole brain","l undefined mPFC","l undefined mPFC","r undefined mPFC","r undefined mPFC", ...
    "l vmPFC","r vmPFC","l dmPFC","r dmPFC","l dHPC","r dHPC","l vHPC","r vHPC","l AMY","r AMY","l REU","r REU","l TH","r TH","l V1","r V1"]);

acr = strings(size(id));
for i = 1 : numel(id)
    if isKey(legend,id(i))
        acr(i) = legend(id(i));
    else
        acr(i) = append('Unknown id: ',id(i));
    end
end