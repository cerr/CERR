function planC = createDummyScan(planC)
%"createDummyScan"
%   Create an empty scan based on the existing scan if it is present, else
%   on the structures if they are present, else on the dose. Add it to the
%   plan at the end of the scan array.
%
%   Currently, voxel size of scan is always .2cm with a 1cm border (5
%   voxels) around the bounding box containing the dose and structures.
%
%   The exception are cases where another scan or rasterSegments are used
%   to set the x,y values.  In this case the old resolution must be used.
%
%   JRA
%
%   Usage: planC = createDummyScan(planC)
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

%Size of rows and cols of voxels
defaultVoxelSize = .2; %cm

%Size of border around min/max x,y vals.
borderSize = 1; %cm

indexS = planC{end};

scans = planC{indexS.scan};
structures = planC{indexS.structures};
doses = planC{indexS.dose};

try
    %Use scan if possible...
    scanStruct = scans(1);
    [xValsScan, yValsScan, zValsScan] = getScanXYZVals(scanStruct);
    scanValid = 0;
catch    
    scanValid = 0;
end
try
    %else try using structures
    [xValsStr, yValsStr, zValsStr, usedRasters] = getStructXYZVals(structures);
    structsValid = 1;
catch
    structsValid = 0;
end
try
    %else use the dose.
    doseStruct = doses(1); % use dose 1.
    [xValsDose, yValsDose, zValsDose] = getDoseXYZVals(doseStruct);
    doseValid = 1;
catch
    doseValid = 0;    
end

if scanValid
    xVals = xValsScan; yVals = yValsScan; zVals = zValsScan;
    resize = 0;
elseif structsValid & usedRasters
    xVals = xValsStr; yVals = yValsStr; zVals = zValsStr;
    resize = 0;
elseif structsValid & doseValid & ~usedRasters
    %A commmon case.
    xVals = [min([xValsStr(:);xValsDose(:)]) max([xValsStr(:);xValsDose(:)])];
    yVals = [min([yValsStr(:);yValsDose(:)]) max([yValsStr(:);yValsDose(:)])];   
    zVals = zValsStr;
    resize = 1;
elseif doseValid & ~structsValid
    xVals = xValsDose; yVals = yValsDose; zVals = zValsDose;
    resize = 1;        
elseif structsValid & ~doseValid
    xVals = xValsStr; yVals = yValsStr; zVals = zValsStr;
    resize = 1;    
else
    error('Not enough information to create dummy scan.')
end

if resize
    xMin = min(xVals); xMax = max(xVals);
    yMin = min(yVals); yMax = max(yVals);
    dx = xMax - xMin;
    dy = yMax - yMin;
    
    imWidthHeight = max(abs(dx), abs(dy));
    xMargin = (imWidthHeight-dx)/2;
    yMargin = (imWidthHeight-dy)/2;

    xVals = xMin-borderSize-xMargin:defaultVoxelSize:xMax+borderSize+xMargin;
    yVals = yMax+borderSize+yMargin:-defaultVoxelSize:yMin-borderSize-yMargin;    
end


ind = length(planC{indexS.scan}) + 1; 

%Create array of all zeros, size of y,x,z vals.
planC{indexS.scan}(ind).scanArray = repmat(uint16(0), [length(yVals) length(xVals) length(zVals)]);
planC{indexS.scan}(ind).scanArray(1,1,1) = 1; %set one voxel on in order that max ~= min.
planC{indexS.scan}(ind).scanType = 'Dummy Scan';
planC{indexS.scan}(ind).scanUID = createUID('scan'); 
%planC{indexS.scan}(ind).uniformScanInfo = [];
%planC{indexS.scan}(ind).scanArrayInferior = [];
%planC{indexS.scan}(ind).scanArraySuperior = [];
%planC{indexS.scan}(ind).thumbnails = [];

scanInfo = initializeScanInfo;

scanInfo(1).grid2Units = xVals(2)-xVals(1);
scanInfo(1).grid1Units = yVals(1)-yVals(2); %negative for y.
scanInfo(1).sizeOfDimension1 = length(xVals);
scanInfo(1).sizeOfDimension2 = length(yVals);
scanInfo(1).xOffset = 0;
scanInfo(1).yOffset = 0;

scanInfo(1).CTOffset = 1000;

%Calculate proper scan offset values based on x,y,z vals.
scanInfo(1).xOffset = xVals(1) + (scanInfo(1).sizeOfDimension2*scanInfo(1).grid2Units)/2;
scanInfo(1).yOffset = yVals(end) + (scanInfo(1).sizeOfDimension1*scanInfo(1).grid1Units)/2;
scanInfo(1).zValue = 0;

zVals = zVals(:)';
sliceThickness = [diff(zVals) zVals(end) - zVals(end-1)];

%Populate scanInfo(1) array.
for i=1:length(zVals)
    scanInfo(1).sliceThickness = sliceThickness(i);
    scanInfo(1).zValue = zVals(i);
    planC{indexS.scan}(ind).scanInfo(i) = scanInfo(1);
end