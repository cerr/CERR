function [filesInCurDir,dirsInCurDir]=rdir(apath)
%Recursively search directories for all files and directories contained
%therein
% Example call: [filesInWorkingDir,dirsInWorkingDir]=rdir(pwd)
%
% 05/09/2013, http://www.matlabexperthelp.com/2012/08/15/recursive-directory-listing/

%% recursively get file contents of all directories
dirInfo=dir(apath);
dirInfo=dirInfo(~(strcmp({dirInfo.name},'..') | strcmp({dirInfo.name},'.' )));
for i=1:length(dirInfo)
    dirInfo(i).fullpath=fullfile(apath,dirInfo(i).name);
end
dirsInCurDir  = dirInfo([dirInfo.isdir]);
filesInCurDir = dirInfo(~[dirInfo.isdir]);
 
%% loop through dirs and get files and dirs inside of current dirs contents
for i=1:length(dirsInCurDir)
    % Call this function again and concatenate results
    [filesInThisDir, dirsInThisDir]=rdir(dirsInCurDir(i).fullpath);
    if ~isempty(filesInThisDir)
        filesInCurDir=[filesInCurDir; filesInThisDir ];
    end
    if ~isempty(dirsInThisDir)
        dirsInCurDir=[dirsInCurDir; dirsInThisDir];
    end   
end