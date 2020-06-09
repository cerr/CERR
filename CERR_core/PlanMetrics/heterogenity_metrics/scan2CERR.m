function planC = scan2CERR(scanNew3M,scanType,register,regParamsS,assocTextureUID,planC)
%function planC = scan2CERR(scanNew3M,scanType,scanDescript,register,regParamsS,assocTextureUID,planC)
%Use this function to put a new scan into planC.
%
%doseNew - 3-D array of scan values.
%scanType - type of scan: CT, MR, Texture etc.
%description - Short description string if desired.
%register - 'CT' or blank (defaults to CT), or non-CT.  If CT, registration geomtrical
%information is taken from the CT scan.  Otherwise, registration data is taken from regParamsS:
%
%regParamsS should contain geometric registration data including the following fields:
%regParamsS.horizontalGridInterval = 0.2 (say)  (x voxel width)
%regParamsS.verticalGridInterval   = 0.2 (say)  (y voxel width)
%regParamsS.coord1OFFirstPoint     = 0.5 (say)  (x value of center of upper left voxel on all slices)
%regParamsS.coord2OFFirstPoint     = 25  (say)  (y value of center of upper left voxel on all slices
%regParamsS.zValues                = [0.5 1.0 1.5 2.0 ...] (say) (z values of all slices)
%
%assocTextureUID  - associated UID of the texture object used to generate
%this scan (texture).
%
% Aditya P. Apte, Sep, 28 2015.
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

if ~exist('planC','var')
    global planC
end

global stateS

indexS = planC{end};

%How many old scans?
prevSets = length(planC{indexS.scan});
setIndex = prevSets + 1;

%Get the latest scan structure:
scanInitS = initializeCERR('scan');
minScan = min(scanNew3M(:));
if minScan >= 0
    scanInitS(1).scanArray = scanNew3M;
    CTOffset = 0;
else
    scanInitS(1).scanArray = scanNew3M - minScan;
    CTOffset = -minScan;
    %scanInitS(1).doseOffset = -minDose;
end
scanInitS(1).scanType = scanType;
scanInitS(1).scanUID = createUID('scan'); 
scanInitS(1).assocTextureUID = assocTextureUID;

siz = size(scanNew3M);
scanInfo = initializeScanInfo;

if nargin > 3 && strcmpi(register,'CT')
    error('Yet to be implemented')
    
    scanNum = getAssociatedScan(assocScanUID);
    
    grid2Units = planC{indexS.scan}(scanNum).scanInfo(1).grid2Units;
    grid1Units = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
    doseInitS(1).horizontalGridInterval = grid2Units;
    doseInitS(1).verticalGridInterval= - abs(grid1Units);

    abGrid1Units = abs(grid1Units);
    abGrid2Units = abs(grid2Units);

    xOffset = planC{indexS.scan}(scanNum).scanInfo(1).xOffset;
    yOffset = planC{indexS.scan}(scanNum).scanInfo(1).yOffset;

    CTWidth = planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2;
    CTHeight = planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1;

    doseInitS(1).coord1OFFirstPoint=  xOffset - (CTWidth/2) * abGrid2Units + abGrid2Units/2;
    doseInitS(1).coord2OFFirstPoint=  yOffset + (CTHeight/2) * abGrid1Units - abGrid1Units/2;

    % get from CT info:

    zValues = [planC{indexS.scan}(scanNum).scanInfo(:).zValue];
    doseInitS(1).zValues = zValues;
    doseInitS(1).delivered='';

elseif nargin > 3 && strcmpi(register,'UniformCT')
    error('Yet to be implemented')
    
    scanNum = getAssociatedScan(assocScanUID);

    uniformInfoS = planC{indexS.scan}(scanNum).uniformScanInfo;
    %[CTUniform3D, uniformInfoS] = getUniformizedCTScan;

    grid2Units = uniformInfoS.grid2Units;
    grid1Units = uniformInfoS.grid1Units;
    doseInitS(1).horizontalGridInterval = grid2Units;
    doseInitS(1).verticalGridInterval= - abs(grid1Units);

    abGrid1Units = abs(grid1Units);
    abGrid2Units = abs(grid2Units);

    xOffset = uniformInfoS.xOffset;
    yOffset = uniformInfoS.yOffset;

    CTWidth = uniformInfoS.sizeOfDimension2;
    CTHeight = uniformInfoS.sizeOfDimension1;
    
    doseInitS(1).coord1OFFirstPoint=  xOffset - (CTWidth/2) * abGrid2Units + abGrid2Units/2;
    doseInitS(1).coord2OFFirstPoint=  yOffset + (CTHeight/2) * abGrid1Units - abGrid1Units/2;

    % get from CT info:

    %sizeArray = getUniformizedSize(planC)
    sizeArray = getUniformScanSize(planC{indexS.scan}(scanNum));
    numSlices = sizeArray(3);
%    numSlices = size(CTUniform3D,3);

    zFirst = uniformInfoS.firstZValue;

    sliceThickness = uniformInfoS.sliceThickness;

    zLast = (numSlices - 1) * sliceThickness + zFirst;

    zValues = zFirst : sliceThickness: zLast;

    doseInitS(1).zValues = zValues;
    doseInitS(1).delivered='';

elseif nargin > 3 && ~strcmpi(register,'UniformCT') && ~strcmpi(register,'CT')

  scanInfo(1).grid2Units = regParamsS.horizontalGridInterval;
  scanInfo(1).grid1Units = regParamsS.verticalGridInterval; %negative for y.
  scanInfo(1).sizeOfDimension1 = siz(1);
  scanInfo(1).sizeOfDimension2 = siz(2);
  %scanInfo(1).xOffset = regParamsS.coord1OFFirstPoint;
  %scanInfo(1).yOffset = regParamsS.coord2OFFirstPoint;
  scanInfo(1).imageType = scanType;
  scanInfo(1).CTOffset = CTOffset;
  scanInfo(1).zValue = 0;
  
  scanInfo(1).xOffset = regParamsS.coord1OFFirstPoint + (scanInfo(1).sizeOfDimension2-1)*scanInfo(1).grid2Units/2;
  scanInfo(1).yOffset = regParamsS.coord2OFFirstPoint + (scanInfo(1).sizeOfDimension1-1)*scanInfo(1).grid1Units/2;
  
  
  %Calculate proper scan offset values based on x,y,z vals.
  %scanInfo(1).xOffset = xValsV(1) + (scanInfo(1).sizeOfDimension2-1)*scanInfo(1).grid2Units/2;
  %scanInfo(1).yOffset = yValsV(end) + (scanInfo(1).sizeOfDimension1-1)*scanInfo(1).grid1Units/2;
  %scanInfo(1).zValue = 0;
  
  %Populate scanInfo(1) array.
  for i=1:length(regParamsS.zValues)
      scanInfo(1).sliceThickness = regParamsS.sliceThickness(i);
      scanInfo(1).zValue = regParamsS.zValues(i);
      scanInitS.scanInfo(i) = scanInfo(1);
  end
  
else

  error('Inputs to scan2CERR are incorrect')

end

% Insert new entry in planC{indexS.scan}
planC{indexS.scan} = dissimilarInsert(planC{indexS.scan},scanInitS, setIndex,[]);  %This way future field additions are automatically included.

% Update min/max scan value in stateS
if ~isempty(stateS)
    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(setIndex).scanUID(max(1,end-61):end))];
    %stateS.scanStats.minScanVal.(scanUID) = single(min(planC{indexS.scan}(setIndex).scanArray(:)));
    %stateS.scanStats.maxScanVal.(scanUID) = single(max(planC{indexS.scan}(setIndex).scanArray(:)));
    minScan = single(min(planC{indexS.scan}(setIndex).scanArray(:)));
    maxScan = single(max(planC{indexS.scan}(setIndex).scanArray(:)));
    stateS.scanStats.CTLevel.(scanUID) = (minScan + maxScan - 2*CTOffset) / 2;
    stateS.scanStats.CTWidth.(scanUID) = maxScan - minScan;
    stateS.scanStats.windowPresets.(scanUID) = 1;
    stateS.scanStats.Colormap.(scanUID) = 'gray256';
end

% Uniformize scan
planC = setUniformizedData(planC, planC{indexS.CERROptions}, setIndex);
