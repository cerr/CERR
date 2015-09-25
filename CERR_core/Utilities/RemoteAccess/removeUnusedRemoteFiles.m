function removeUnusedRemoteFiles()
%function removeUnusedRemoteFiles()
%
%checks for validity of remote Files and removes them if they are unused.
%stateS.reqdRemoteFiles is used for checking remoteness of variables.
%
%APA, 07/26/2006
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

global planC stateS

% % obtain path
if isempty(stateS) | ~isfield(stateS,'CERRFile') | ~isfield(stateS,'reqdRemoteFiles')
    return;
else
    [pathstr, name, ext] = fileparts(stateS.CERRFile);
end

%Prepare a list of remote files.
% remoteFiles = listRemoteFiles(planC, 0);
remoteFiles = listRemoteScanAndDose(planC);
filesLocal = [];
remoteFullFile = {};
for i = 1:length(remoteFiles)
    switch upper(remoteFiles(i).storageType)
        case {'LOCAL'}
            remotePathLocal{i} = remoteFiles(i).remotePath;
            filesLocal{i} = remoteFiles(i).filename;
            remoteFullFile{i} = fullfile(remotePathLocal{i},filesLocal{i});
    end
end

% delete unnecessary remote files in original plan that were created
% temporarily
for i = 1:length(remoteFullFile)
    if ~ismember(remoteFullFile{i},stateS.reqdRemoteFiles)
        delete(remoteFullFile{i})
    end
end

%delete unnecessary remote files in original plan that changed
for i = 1:length(stateS.reqdRemoteFiles)
    if ~ismember(stateS.reqdRemoteFiles(i),remoteFullFile) & isequal(fileparts(stateS.reqdRemoteFiles{i}),fullfile(pathstr,[name,'_store']))
        delete(stateS.reqdRemoteFiles{i})
    end
end
