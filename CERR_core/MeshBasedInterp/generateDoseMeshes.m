function generateDoseMeshes()
%function clearDoseMeshes()
%This function generatessurface meshes for the dose whose meshRep flag is
%set to 1. Note that the The contourLevels are selected from current options.
%
%APA, 06/21/07
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

global planC
indexS = planC{end};

%Set Matlab path to directory containing the library
currDir = cd;
meshDir = fileparts(which('libMeshContour.dll'));
cd(meshDir)

%Generate new dose meshes
contourLevels = getIsoDoseLevels;
waitbarH = waitbar(0,'Generating surface meshes for dose...');
for doseNum = 1:length(planC{indexS.dose})
    if isfield(planC{indexS.dose}(doseNum),'meshRep') && isnumeric(planC{indexS.dose}(doseNum).meshRep) && planC{indexS.dose}(doseNum).meshRep == 1
        doseUID = planC{indexS.dose}(doseNum).doseUID;
        doseVolume = planC{indexS.dose}(doseNum).doseArray;
        doseVolume = permute(doseVolume,[2 1 3]);
        [xVals, yVals, zVals] = getDoseXYZVals(planC{indexS.dose}(doseNum));
        calllib('libMeshContour','loadVolumeData',doseUID,xVals, yVals, zVals, double(doseVolume))
        for level = 1:length(contourLevels)
            calllib('libMeshContour','generateSurface', doseUID, [doseUID,'_',num2str(contourLevels(level))], double(contourLevels(level)), uint16(10));
        end
        calllib('libMeshContour','clear',doseUID)
    end
    waitbar(doseNum/length(planC{indexS.dose}),waitbarH)
end
close(waitbarH)

%switch back the current irectory
cd(currDir)
