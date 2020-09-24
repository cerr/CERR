function addCERRtoPath(pathStr)
% function addCERRtoPath(pathStr)
%
% This function adds sub-directories from CERR distribution to Matlab/Octave path
% pathStr is the absolute path of CERR.
% 
% APA, 7/30/2020
  
pathC = genpath(pathStr);
pathC = strsplit(pathC,';');
indGitV = cellfun(@isempty,strfind(pathC,{'.git'}));
pathC = pathC(indGitV);
addpath(strjoin(pathC,';'))

