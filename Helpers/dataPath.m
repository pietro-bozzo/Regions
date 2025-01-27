function path = dataPath()
% dataPath Get path to Data folder in Regions, provided that this function is in one of its subfolder

split = strsplit(mfilename('fullpath'),'Regions');
if size(split,2) < 2
  error('Unable to get path to Data folder')
end
path = [split{1},'Regions/Data'];