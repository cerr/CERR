function success = addToPath(cerrDir)
% function success = addCerrToPath(cerrDir)
%
% This function adds subfolders in cerrDir to MATLAB/OCTAVE path excluding
% the .git folders.
%
% Example:
% cerrDir = 'C:\Path\to\CERR\';
% addToPath(cerrDir)
%
% APA, 7/29/2021

pathStr = genpath(cerrDir);
if ispc
    indSemiColonV = strfind(pathStr,';');
else
    indSemiColonV = strfind(pathStr,':');
end
indGitV = strfind(pathStr,'.git');
minIndV = arrayfun(@(x) max(indSemiColonV(indSemiColonV<x)),indGitV);
maxIndV = arrayfun(@(x) min(indSemiColonV(indSemiColonV>x)),indGitV);
for i = length(minIndV):-1:1
    pathStr(minIndV(i):maxIndV(i)-1) = [];
end
addpath(pathStr)

success = 1;
