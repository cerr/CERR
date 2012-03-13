function varargout = mlog(command,directory,varargin)
%function varargout = mlog(command,directory,varargin)
%
%Matlab-based log of files and folders
%
%This function currently supports two options:
%
%1> mlog('LOG',directory,save_flag,logName), %or
% [CERRVer,VerDate] = CERRCurrentVersion;
% mlog('LOG',getCERRPath,1,[CERRVer,'_', VerDate])
% directory: is the absolute path of the directory to be logged.
% save_flag: is a flag to tell the routine whether or not to save the log (1=save).
% logName: is the fileName to save log.
%2> [filesChangedC,filesRemovedC,filesAddedC,dirsChangedC,dirsRemovedC,dirsAddedC] = mlog('DIFF',getCERRPath);
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

switch upper(command)

    case 'LOG'
        clear logFilesAndDir
        logS = logFilesAndDir(directory);
        logDir = fullfile(directory,'Log','versions');
        if ~exist(logDir,'dir')
            mkdir(directory,'versions')
        end        
        if length(varargin)>1 && varargin{1}==1 %(save_flag = varargin{1};)
            logName = varargin{2};
            save(fullfile(logDir,[logName,'.mat']),'logS')
        end
        varargout{1} = logS;

    case 'DIFF'
        hWait = waitbar(0,'Checking integrity of CERR m-files. Please wait...');
        logPath = fullfile(getCERRPath,'Log','versions');
        if ~exist(logPath,'dir')
            return;
        else
            %Get a fresh log
            clear logFilesAndDir
            logNewS = mlog('LOG',getCERRPath, 1, 'logCurrent');
            dirS = dir(logPath);
            dirS = dirS(3:end); %Assume 1st two directories are . and ..
        end
        [CERRVer, VerDate] = CERRCurrentVersion;
        %Find the log-file associated with the current version of CERR
        indFile = strmatch([CERRVer,'_', VerDate,'.mat'],{dirS.name},'exact');
        if ~isempty(indFile) %compare
            load(fullfile(logPath,dirS(indFile).name)) %loads logS variable
            [filesChangedC,filesRemovedC,filesAddedC,dirsChangedC,dirsRemovedC,dirsAddedC] = compareLogs(logS,logNewS,hWait);
            if isempty(filesChangedC) && isempty(filesRemovedC) && isempty(filesAddedC) && isempty(dirsChangedC) && isempty(dirsRemovedC) && isempty(dirsAddedC)
                disp('Nothing changed in CERR on your machine.')
            end
        else
            warning('Log not found...')
            close(hWait)
            varargout{1} = [];
            varargout{2} = [];
            varargout{3} = [];
            varargout{4} = [];
            varargout{5} = [];
            varargout{6} = [];            
            return
        end

        varargout{1} = filesChangedC;
        varargout{2} = filesRemovedC;
        varargout{3} = filesAddedC;
        varargout{4} = dirsChangedC;
        varargout{5} = dirsRemovedC;
        varargout{6} = dirsAddedC;
        
end

return;
%% end of main


%---------------------- SUPPORTING FUNCTIONS

function [filesChangedC,filesRemovedC,filesAddedC,dirsChangedC,dirsRemovedC,dirsAddedC] = compareLogs(logOldS,logNewS,hWait)
%function compareLoggedDir(logOld,logNew)
%This function lists the files and directories in logOld which do not exist
%in logNew
%
%APA, 11/10/2006

%Check files
fNamesC = fieldnames(logOldS.fileLog);
numFiles = length(fNamesC);
dNamesC = fieldnames(logOldS.dirLog);
numDirs = length(dNamesC);
fileCheckV = zeros(numFiles,1);
indRemoved = [];

for i = numFiles:-1:1
    waitbar((numFiles-i)*1/(numFiles+numDirs),hWait)
    try
        %wy fileCheckV(i) = abs(logOldS.fileLog.(fNamesC{i}) - logNewS.fileLog.(fNamesC{i}));
        fileCheckV(i) = strcmpi(logOldS.fileLog.(fNamesC{i}), logNewS.fileLog.(fNamesC{i}));
    catch
        indRemoved = [indRemoved i];
    end
end

%%
%wy indChanged = find(fileCheckV>eps);
indChanged = find(fileCheckV==0);
filesChangedC = fNamesC(indChanged);
filesRemovedC = fNamesC(indRemoved);
fnamesNewC = fieldnames(logNewS.fileLog);
indAdded = ~ismember(fnamesNewC,fNamesC);
filesAddedC = fnamesNewC(indAdded);

%Check directories
dirCheckV = zeros(numDirs,1);
indRemoved = [];
for i = numDirs:-1:1
    waitbar(numFiles/(numFiles+numDirs) + (numDirs-i)*1/(numFiles+numDirs),hWait)
    try
        dirCheckV(i) = logOldS.dirLog.(dNamesC{i}) - logNewS.dirLog.(dNamesC{i});
    catch
        indRemoved = [indRemoved i];
    end
end
indChanged = find(dirCheckV>eps);
dirsChangedC = dNamesC(indChanged);
dirsRemovedC = dNamesC(indRemoved);
dnamesNewC = fieldnames(logNewS.dirLog);
indAdded = ~ismember(dnamesNewC,dNamesC);
dirsAddedC = dnamesNewC(indAdded);

close(hWait)

return;

