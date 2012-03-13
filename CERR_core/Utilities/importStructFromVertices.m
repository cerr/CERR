%importStructFromVertices.m
%  
%Script to create CERR-structure, given vertices and connectivity.
%
%This code assumes that the vertices, connectivity and normals are stored in
%'meshS' structure. Normals are not required as input and are calculated in this code.
%Example of meshS structure: meshS is of class struct array
%meshS = 
%     vertices: [27048x3 double]
%    triangles: [54092x3 uint32]
%      normals: [27048x3 double]
%
%APA, 05/13/2008
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

scanIndex = 1;

%set Matlab path to directory containing the Mesh-library
currDir = cd;
meshDir = fileparts(which('libMeshContour.dll'));
cd(meshDir)
loadlibrary('libMeshContour','MeshContour.h')

%Re/compute vertex normals
meshNormals = [];
numVertices = size(meshS.vertices,1);
hWait = waitbar(0,'Computing vertex normals. Please wait...');
for i=1:numVertices
    meshNormals(i,:) = calcVertexNormal(i,meshS);
    waitbar(i/numVertices,hWait)
end
close(hWait)
meshS.normals = meshNormals;

%Create new CERR-structure
newStruct = newCERRStructure(scanIndex, planC);
newStruct.structureName = 'New Import';
structUID = newStruct.strUID;

%Load surface mesh
calllib('libMeshContour','loadSurface',structUID,meshS);

%Cut the surface at CT z-values and create CERR contour
[jnkX, jnkY, scanZv] = getScanXYZVals(planC{indexS.scan}(scanIndex));
transM = eye(4); %Assume no transM. must be updated if transM is present.
for i=1:length(scanZv)
    coord = scanZv(i);
    pointOnPlane = [0 0 coord] - transM(1:3,4)';
    planeNormal = (inv(transM(1:3,1:3))*[0 0 1]')';
    pointOnPlane = (inv(transM(1:3,1:3))*pointOnPlane')';    
    contourS    = calllib('libMeshContour','getContours',structUID,single(pointOnPlane),single(planeNormal),single([0 1 0]),single([1 0 0]));
    if ~isempty(contourS) && length(length(contourS.segments)) > 0
        for segNum = 1:length(contourS.segments)
            pointsM = applyTransM(transM,contourS.segments(segNum).points);
            contour_str(i).segments(segNum).points(:,1) = pointsM(:,1);
            contour_str(i).segments(segNum).points(:,2) = pointsM(:,2);
            contour_str(i).segments(segNum).points(:,3) = coord*pointsM(:,1).^0;
        end
    else
        contour_str(i).segments(1).points = [];
    end
end

%Change directory back
cd(currDir)

newStruct.contour = contour_str;
newStruct.associatedScan = scanIndex;
newStruct.assocScanUID = planC{indexS.scan}(scanIndex).scanUID;
newStruct.meshRep = 0;
numStructs = length(planC{indexS.structures});

%Append new structure to planC.
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStruct, numStructs+1, []);

%Create Raster Segments
planC = getRasterSegs(planC, numStructs+1);

%Update uniformized data.
planC = updateStructureMatrices(planC, numStructs+1);

stateS.structsChanged = 1;
CERRRefresh

return;