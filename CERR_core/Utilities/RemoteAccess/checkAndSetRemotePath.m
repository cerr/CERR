function flag = checkAndSetRemotePath()
%function flag = checkAndSetRemotePath()
%
%checks for validity of remotePaths of remotely stored variables and
%corrects them if the .mat files for remote variables exist in the
%subdirectory ...planDir\planName_store.
%OUTPUT:
%   flag=0 when paths could be set correctly.
%   flag=1 when remotely stored files could not be found.
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
indexS = planC{end};
[fpath,fname] = fileparts(stateS.CERRFile);
storePath = fullfile(fpath,[fname,'_store']);
flag = 0;

% Check if any IM is remote
for i = 1:length(planC{indexS.IM})
    if ~isempty(planC{indexS.IM}(i).IMDosimetry.beams) && ~isLocal(planC{indexS.IM}(i).IMDosimetry.beams(1).beamlets) && exist(fullfile(storePath,planC{indexS.IM}(i).IMDosimetry.beams(1).beamlets.filename))==2
        if ~isequal(fullfile(planC{indexS.IM}(i).IMDosimetry.beams(1).beamlets.remotePath,planC{indexS.IM}(i).IMDosimetry.beams(1).beamlets.filename),fullfile(storePath,planC{indexS.IM}(i).IMDosimetry.beams(1).beamlets.filename))
            for iBeam = 1:length(planC{indexS.IM}(i).IMDosimetry.beams)
                planC{indexS.IM}(i).IMDosimetry.beams(iBeam).beamlets.remotePath = storePath;
            end
        end
    elseif ~isempty(planC{indexS.IM}(i).IMDosimetry.beams) && ~isLocal(planC{indexS.IM}(i).IMDosimetry.beams(1).beamlets) && exist(fullfile(storePath,planC{indexS.IM}(i).IMDosimetry.beams(1).beamlets.filename))~=2
        flag = 1;
        return
    end
end

% check if any doseArray is remote
for i = 1:length(planC{indexS.dose})
    if ~isLocal(planC{indexS.dose}(i).doseArray) && exist(fullfile(storePath,planC{indexS.dose}(i).doseArray.filename))==2
        % i.e. .mat file is under _store directory. Now check if absolute
        % path is correct, else reassign remote path
        if ~isequal(fullfile(planC{indexS.dose}(i).doseArray.remotePath,planC{indexS.dose}(i).doseArray.filename),fullfile(storePath,planC{indexS.dose}(i).doseArray.filename))
            planC{indexS.dose}(i).doseArray.remotePath = storePath;
        end
    elseif ~isLocal(planC{indexS.dose}(i).doseArray) && exist(fullfile(storePath,planC{indexS.dose}(i).doseArray.filename))~=2
        flag = 1;
        return
    end
end

% check if any scanArray, Sup, Inf are remote
for i = 1:length(planC{indexS.scan})
    if ~isLocal(planC{indexS.scan}(i).scanArray) && exist(fullfile(storePath,planC{indexS.scan}(i).scanArray.filename))==2
        % i.e. .mat file is under _store directory. Now check if absolute
        % path is correct, else reassign remote path
        if ~isequal(fullfile(planC{indexS.scan}(i).scanArray.remotePath,planC{indexS.scan}(i).scanArray.filename),fullfile(storePath,planC{indexS.scan}(i).scanArray.filename))
            planC{indexS.scan}(i).scanArray.remotePath = storePath;
        end
    elseif ~isLocal(planC{indexS.scan}(i).scanArray) && exist(fullfile(storePath,planC{indexS.scan}(i).scanArray.filename))~=2
        flag = 1;
        return
    end
    if ~isLocal(planC{indexS.scan}(i).scanArraySuperior) && exist(fullfile(storePath,planC{indexS.scan}(i).scanArraySuperior.filename))==2
        % i.e. .mat file is under _store directory. Now check if absolute
        % path is correct, else reassign remote path
        if ~isequal(fullfile(planC{indexS.scan}(i).scanArraySuperior.remotePath,planC{indexS.scan}(i).scanArraySuperior.filename),fullfile(storePath,planC{indexS.scan}(i).scanArraySuperior.filename))
            planC{indexS.scan}(i).scanArraySuperior.remotePath = storePath;
        end
    elseif ~isLocal(planC{indexS.scan}(i).scanArraySuperior) && exist(fullfile(storePath,planC{indexS.scan}(i).scanArraySuperior.filename))~=2
        flag = 1;
        return
    end
    if ~isLocal(planC{indexS.scan}(i).scanArrayInferior) && exist(fullfile(storePath,planC{indexS.scan}(i).scanArrayInferior.filename))==2
        % i.e. .mat file is under _store directory. Now check if absolute
        % path is correct, else reassign remote path
        if ~isequal(fullfile(planC{indexS.scan}(i).scanArrayInferior.remotePath,planC{indexS.scan}(i).scanArrayInferior.filename),fullfile(storePath,planC{indexS.scan}(i).scanArrayInferior.filename))
            planC{indexS.scan}(i).scanArrayInferior.remotePath = storePath;
        end
    elseif ~isLocal(planC{indexS.scan}(i).scanArrayInferior) && exist(fullfile(storePath,planC{indexS.scan}(i).scanArrayInferior.filename))~=2
        flag = 1;
        return
    end
end
