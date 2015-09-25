function remoteFiles = listRemoteScanAndDose(planC)
%"listRemoteScanAndDose"
%   Returns a structure array of remote scan and dose variables in planC 
%   that are stored remotely, for the purpose of updating the remote files.
%
%APA 08/17/05
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
%
%Usage:
%   remoteFiles = listRemoteScanAndDose(planC)

remoteFiles = [];

if isempty(planC)    
    return;
end

indexS = planC{end};
% check for remote files in scan structure
for i = 1:length(planC{indexS.scan})
    if ~isLocal(planC{indexS.scan}(i).scanArray) && ~isempty(remoteFiles)
        remoteFiles(end+1) = planC{indexS.scan}(i).scanArray; %fullfile(planC{indexS.scan}(i).scanArray.remothPath, planC{indexS.scan}(i).scanArray.fileName);
        remoteFiles(end+1) = planC{indexS.scan}(i).scanArraySuperior; 
        remoteFiles(end+1) = planC{indexS.scan}(i).scanArrayInferior;
    elseif ~isLocal(planC{indexS.scan}(i).scanArray) && isempty(remoteFiles)
        remoteFiles = planC{indexS.scan}(i).scanArray; %fullfile(planC{indexS.scan}(i).scanArray.remothPath, planC{indexS.scan}(i).scanArray.fileName);
        remoteFiles(end+1) = planC{indexS.scan}(i).scanArraySuperior; 
        remoteFiles(end+1) = planC{indexS.scan}(i).scanArrayInferior;        
    end
end

% check for remote files in dose structure
for i = 1:length(planC{indexS.dose})
    if ~isLocal(planC{indexS.dose}(i).doseArray) && ~isempty(remoteFiles)
        remoteFiles(end+1) = planC{indexS.dose}(i).doseArray;
    elseif ~isLocal(planC{indexS.dose}(i).doseArray) && isempty(remoteFiles)
        remoteFiles = planC{indexS.dose}(i).doseArray;
    end
end

% check for remote files in IM structure
for i = 1:length(planC{indexS.IM})
    if ~isempty(planC{indexS.IM}(i).IMDosimetry.beams) && ~isLocal(planC{indexS.IM}(i).IMDosimetry.beams(1).beamlets)
       for iBeam = 1:length(planC{indexS.IM}(i).IMDosimetry.beams)
           if isempty(remoteFiles)
               remoteFiles = planC{indexS.IM}(i).IMDosimetry.beams(iBeam).beamlets;
           else
               remoteFiles(end+1) = planC{indexS.IM}(i).IMDosimetry.beams(iBeam).beamlets;
           end
       end
    end
end

