function makeFolders(session)
% makeFolders Create Pietro folders in specified session, if missing
%
% arguments:
% session (1,:) char              path to a Session .xml file

arguments
  session (1,:) char
end

path = fileparts(session);

if ~isfolder([path,'/Pietro'])
  mkdir([path,'/Pietro'])
end
if ~ isfolder([path,'/Pietro/AvalanchesByState'])
  mkdir([path,'/Pietro/AvalanchesByState'])
end
if ~ isfolder([path,'/Pietro/Assemblies'])
  mkdir([path,'/Pietro/Assemblies'])
end