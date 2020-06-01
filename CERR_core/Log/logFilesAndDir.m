function logS = logFilesAndDir(directory)
%function logS = logFilesAndDir(directory)
%This function obtains a log of all the files and sub-directories within
%the passed directory.
%INPUT: the absolute path of directory to be logged
%OUTPUT: logS - Sstructure with two fields dirLog and fileLog
%                 logS.dirLog is a matlab structure where each field stores
%                 version and size information for directory with matching name.
%                 logS.filePath is a matlab structure where each field stores
%                 version and size information for m-file with matching name.
%EXAMPLE: logS = logFilesAndDir(getCERRPath);
%
%APA 05/27/2008
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

persistent logStrTmp dirIndex fileIndex
allDirS = dir(directory);
if isempty(dirIndex)
    dirIndex = 1;
end
if isempty(fileIndex)
    fileIndex = 1;
end
for dirNum = 1:length(allDirS)
    if ~allDirS(dirNum).isdir && strcmpi(allDirS(dirNum).name(end-1:end),'.m')
        %Record as hash-Key
        try
%             logStrTmp.fileLog.(strtok(allDirS(dirNum).name,'.')) = allDirS(dirNum).bytes + datenum(allDirS(dirNum).date);
            if ispc
                logStrTmp.fileLog.(strtok(allDirS(dirNum).name,'.')) = md5(fullfile(directory,allDirS(dirNum).name));
            elseif isunix
                logStrTmp.fileLog.(strtok(allDirS(dirNum).name,'.')) = md5_Linux32(fullfile(directory,allDirS(dirNum).name));
            end
        catch
            disp('md5 error...');
        end
    elseif allDirS(dirNum).isdir && ~strcmp(allDirS(dirNum).name,'.') && ~strcmp(allDirS(dirNum).name,'..') && ~strcmpi(allDirS(dirNum).name,'Log') && ~strcmpi(allDirS(dirNum).name,'CVS')
        dirName = allDirS(dirNum).name;
        indRemove = [];
        indRemove = [indRemove strfind(dirName,' ')];
        indRemove = [indRemove strfind(dirName,'.')];
        indRemove = [indRemove strfind(dirName,'-')];
        indRemove = [indRemove strfind(dirName,'+')];
        dirName(indRemove) = '_';
        logStrTmp.dirLog.(['dir_',dirName]) = allDirS(dirNum).bytes + datenum(allDirS(dirNum).date);
        if ispc
            logStrTmp = logFilesAndDir([directory, allDirS(dirNum).name, '\']);
        elseif isunix
            logStrTmp = logFilesAndDir([directory, allDirS(dirNum).name, '/']);
        end
    end
end
logS = logStrTmp;

return;
% end of function logFilesAndDir
