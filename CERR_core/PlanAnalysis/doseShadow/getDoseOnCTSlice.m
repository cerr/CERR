function doseM = getDoseOnCTSlice(sliceNum, doseNum, planC, stateS, subset)
%Returns the dose matrix on a CT slice.
%This code was broken out from sliceCallBack and originated
%with Joe Deasy.
%
%By JRA 10/17/03
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
%sliceNum      :    slice on which to get dose (1..n)
%doseNum       :    doseSet to consult (1..n)
%planC         :    planC
%stateS        :    stateS
%subset        :    a mask that indicates a region on the slice in which we
%                   want dose calculated--the rest is zeros.  Leave subset
%                   empty to get the full dose. Subset must be the same size 
%                   as the CT scan.
%
%doseM         :    dose matrix, interpolated to fit CT scan.
indexS = planC{end};

zValue = planC{indexS.scan}(stateS.currentScan).scanInfo(sliceNum).zValue;
dose_zValues = planC{indexS.dose}(stateS.doseSet).zValues;

%assumption is made that dimension2 and dimension1 are the same size.
n = planC{indexS.scan}(stateS.currentScan).scanInfo(sliceNum).sizeOfDimension2;
m = planC{indexS.scan}(stateS.currentScan).scanInfo(sliceNum).sizeOfDimension1;
    
if [zValue > max(dose_zValues)] | [zValue < min(dose_zValues)]
    doseM = zeros(n,n); %No dose on this slice. Out of range.
    return
end
    
dose3M = getDoseArray(planC{indexS.dose}(stateS.doseSet));
doseSize = size(dose3M);

slicewewant = find(abs(dose_zValues-zValue) <= 25*eps);
if isempty(slicewewant)
  cranialSlice = max(find([dose_zValues <= zValue]));
  caudalSlice = min(find([dose_zValues >= zValue]));
else
  cranialSlice = slicewewant;
  caudalSlice = slicewewant;
end

%Two-step interpolation:  first get the dose image
%3-D interpolated at the plane of the CT-scan.
%Then 2-D interpolate to get doses at all the CT data points within
%the dose grid.

if cranialSlice == caudalSlice	
    xyInterpDose2M = dose3M(:,:,cranialSlice);
    %No interpolation in z is necessary	
else     
    % This is a little to a lot faster. Contrib by Nathan Childress 6.12.03
    deltaZ = (dose_zValues(caudalSlice) - zValue) / (dose_zValues(caudalSlice) - dose_zValues(cranialSlice));
    xyInterpDose2M = dose3M(:,:,cranialSlice)*deltaZ + dose3M(:,:,caudalSlice)*(1-deltaZ);       
end

%Now interpolate in 2-D onto a grid.
%To do this get row and column coordinates of the upper left and lower right
%points *in CT image coordinates*.  Then use meshgrid as input to interp2,
%as done above.

delta_x_CT      =   planC{indexS.scan}(stateS.currentScan).scanInfo(sliceNum).grid1Units; %assumes grid2Units = grid1Units
imageWidth =   planC{indexS.scan}(stateS.currentScan).scanInfo(sliceNum).sizeOfDimension2;

xMin = planC{indexS.dose}(stateS.doseSet).coord1OFFirstPoint;
yMax = planC{indexS.dose}(stateS.doseSet).coord2OFFirstPoint;

%Get any offset of CT scans to apply (neg) to structures
if ~isempty(planC{indexS.scan}(stateS.currentScan).scanInfo(1).xOffset)
    xCTOffset = planC{indexS.scan}(stateS.currentScan).scanInfo(1).xOffset;
else
    xCTOffset = 0;
end
if ~isempty(planC{indexS.scan}(stateS.currentScan).scanInfo(1).yOffset)
    yCTOffset = planC{indexS.scan}(stateS.currentScan).scanInfo(1).yOffset;
else
    yCTOffset = 0;
end

%First get the upper left dose value
x1 = xMin/delta_x_CT;
y1 = yMax/delta_x_CT;
[row1, col1] = aapmtom(x1, y1, xCTOffset/delta_x_CT, yCTOffset/delta_x_CT, imageWidth);

delta_x_dose = planC{indexS.dose}(stateS.doseSet).horizontalGridInterval;
delta_y_dose = abs(planC{indexS.dose}(stateS.doseSet).verticalGridInterval);

%Now get the opposite corner coordinates:
xMax = xMin + (doseSize(2) - 1) * delta_x_dose;
yMin = yMax - (doseSize(1) - 1) * delta_y_dose;

x2 = xMax/delta_x_CT;
y2 = yMin/delta_x_CT;
[row2, col2] = aapmtom(x2, y2, xCTOffset/delta_x_CT, yCTOffset/delta_x_CT, imageWidth);

%Get corners of dose matrix in CT row, column coord system, stored in sliceCallBack:
   
%Now generate the row and column values of all the CT voxels
persistent colsCTM
persistent rowsCTM
persistent index
if isempty(colsCTM) | index~=n
    [colsCTM, rowsCTM] = meshgrid(1:n,1:n);
    index = n;
end

delta_x_dose = planC{indexS.dose}(doseNum).horizontalGridInterval;
delta_y_dose = abs(planC{indexS.dose}(doseNum).verticalGridInterval);
delta_ct = planC{indexS.scan}(stateS.currentScan).scanInfo(sliceNum).grid1Units;

colsRelDoseM = 1 + (colsCTM - col1) * (delta_ct/delta_x_dose);
rowsRelDoseM = 1 + (rowsCTM - row1) * (delta_ct/delta_y_dose);

colsRelV = colsRelDoseM(:);
rowsRelV = rowsRelDoseM(:);

%Create a mask (indL) of region we need to interpolate over. Apply to
%the rows and columns of the CT mesh.  Saves 7% time over previous mtd.
colLowerBound=ceil(col1 + (delta_ct/delta_x_dose));
colUpperBound=floor(col2 - (delta_ct/delta_x_dose));
rowLowerBound=ceil(row1 + (delta_ct/delta_y_dose));
rowUpperBound=floor(row2 - (delta_ct/delta_y_dose));  
indL = logical(uint8(zeros(n,n))); %This seems right, but perhaps 1, 2?
indL(rowLowerBound:rowUpperBound,colLowerBound:colUpperBound) = 1;


%Fill with zeros, or offset.  Prevents margins with (offset) dose from being reset to 0.
doseV = ones(size(colsRelV)); %TIMES offset.

if exist('subset')
    indL = indL & subset;
end

cols2V = colsRelV(indL);
rows2V = rowsRelV(indL);

doseInterpV = interp2(xyInterpDose2M, cols2V, rows2V, 'linear');

doseV(indL) = doseInterpV;
doseM = reshape(doseV,n,n);