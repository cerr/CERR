function planC = copyStrToScan_meshBased(structNum,scanNum,planC)
%function planC = copyStrToScan_meshBased(structNum,scanNum,planC)
%
%This function derives a new structure from structNum which is associated
%to scanNum. The naming convention for this new structure is 
%[structName assoc scanNum]. If structNum is already associated to scanNum,
%the unchanged planC is returned back. 
%
%APA, 11/13/07
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

global stateS

if ~exist('planC')
    global planC
end

indexS = planC{end};

%return if structNum is already associated to scanNum
assocScanNum = getAssociatedScan(planC{indexS.structures}(structNum).assocScanUID);
if assocScanNum == scanNum
    warning(['Structure Number ',num2str(structNum),' is already assocoated with scan ',num2str(scanNum)])
    return;
end

%set Matlab path to directory containing the Mesh-library
currDir = cd;
if ispc
    meshDir = fileparts(which('libMeshContour.dll'));
    cd(meshDir);
    loadlibrary('libMeshContour','MeshContour.h');
elseif isunix
    meshDir = fileparts(which('libMeshContour.so'));
    cd(meshDir);
    loadlibrary('libMeshContour.so','MeshContour.h');
end

%Create Mesh-representation if it does not exist
clearMeshFlag = 0;
smoothIter = 10;

if ~isfield(planC{indexS.structures}(structNum),'meshRep') || (isfield(planC{indexS.structures}(structNum),'meshRep') && ~isempty(planC{indexS.structures}(structNum).meshRep) && planC{indexS.structures}(structNum).meshRep == 0)  || (isfield(planC{indexS.structures}(structNum),'meshRep') && isempty(planC{indexS.structures}(structNum).meshRep))

    assocScan = getStructureAssociatedScan(structNum,planC);
    [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(assocScan));
    structUID   = planC{indexS.structures}(structNum).strUID;
    [rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
    [mask3M, uniqueSlices] = rasterToMask(rasterSegments, assocScan);
    mask3M = permute(mask3M,[2 1 3]);
    %Handle structures defined on single CT slice
    if size(mask3M,3)==1
        if uniqueSlices==1
            mask3M(:,:,2) = zeros(size(mask3M));
            uniqueSlices = [uniqueSlices uniqueSlices+1];
        elseif uniqueSlices==length(zVals)
            mask3M(:,:,2) = zeros(size(mask3M));
            uniqueSlices = [uniqueSlices uniqueSlices-1];
        else
            mask3M(:,:,2) = zeros(size(mask3M));
            uniqueSlices = [uniqueSlices uniqueSlices+1];
        end
    end
    calllib('libMeshContour','loadVolumeAndGenerateSurface',structUID,xVals,yVals,zVals(uniqueSlices), double(mask3M),0.5, uint16(smoothIter))
    %Store mesh under planC
    planC{indexS.structures}(structNum).meshS = calllib('libMeshContour','getSurface',structUID);
    clearMeshFlag = 1;
end


%Get transformation matrix
if ~isfield(planC{indexS.scan}(scanNum),'transM') | isempty(planC{indexS.scan}(scanNum).transM)
    transMnew = eye(4);
else    
    transMnew = planC{indexS.scan}(scanNum).transM;
end
if ~isfield(planC{indexS.scan}(assocScanNum),'transM') | isempty(planC{indexS.scan}(assocScanNum).transM) 
    transMold = eye(4);
else    
    transMold = planC{indexS.scan}(assocScanNum).transM;
end
transM = inv(transMnew)*transMold;

%Get z-coordinates of scan
[jnk1,jnk2,scanZv] = getScanXYZVals(planC{indexS.scan}(scanNum));
for i = 1:length(scanZv)
    coord = scanZv(i);
    pointOnPlane = [0 0 coord] - transM(1:3,4)';
    planeNormal = (inv(transM(1:3,1:3))*[0 0 1]')';
    pointOnPlane = (inv(transM(1:3,1:3))*pointOnPlane')';
    structUID   = planC{indexS.structures}(structNum).strUID;
    contourS    = calllib('libMeshContour','getContours',structUID,single(pointOnPlane),single(planeNormal),single([0 1 0]),single([1 0 0]));
    if ~isempty(contourS) && length(length(contourS.segments)) > 0
        for segNum = 1:length(contourS.segments)
            pointsM = applyTransM(transM,contourS.segments(segNum).points);
            contour(i).segments(segNum).points(:,1) = pointsM(:,1);
            contour(i).segments(segNum).points(:,2) = pointsM(:,2);
            contour(i).segments(segNum).points(:,3) = coord*pointsM(:,1).^0;
        end
    else
        contour(i).segments(1).points = [];
    end
end

%Clear Surface Mesh
unloadlibrary('libMeshContour')
if clearMeshFlag
    planC{indexS.structures}(structNum).meshRep = 0;
    planC{indexS.structures}(structNum).meshS = [];
end

%Change directory back
cd(currDir)

strname = [planC{indexS.structures}(structNum).structureName,' asoc ',num2str(scanNum)];

newstr = newCERRStructure(scanNum);
newstr.contour = contour;
newstr.structureName = strname;
newstr.associatedScan = scanNum;
newstr.assocScanUID = planC{indexS.scan}(scanNum).scanUID;
newstr.meshRep = 0;
numStructs = length(planC{indexS.structures});

%Append new structure to planC.
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newstr, numStructs+1, []);

%Create Raster Segments
planC = getRasterSegs(planC, numStructs+1);

%Update uniformized data.
[jnk, relStructNum] = getStructureAssociatedScan(numStructs+1,planC);
if relStructNum==1
    planC = setUniformizedData(planC);
else
    planC = updateStructureMatrices(planC, numStructs+1);
end

if isfield(stateS,'handle') && ishandle(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
    CERRRefresh
end

return;
