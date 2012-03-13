function [doseShadowM, sliceNumsM] = getStructureShadowMask(rasterSegs, x, y, planC, stateS, hWaitbar)
%Given the raster segments of a structure, create a matrix that is the
%projection of the max/min/mean dose in that structure onto the xy plane. 
%x and y are the size of the plane., eg 512x512.  Also returns 
%a matrix indicating what slice number each max/min dose pixel came from.
%
% Warnings: meanDose assumes that slice intervals are all the same
%           max number of slices is currently 255, uint8
%           third layer of sliceNumsM is the number of slices used for mean
%
% JRA 10/17/03
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
%rasterSegs     : all rasterSegments of structure
%x,y            : dimensions of CT scan
%planC          : planC
%stateS         : stateS
%waitbar        : handle of optional waitbar
%
%doseShadowM     : (:,:,1)=maxDose, (:,:,2)=minDose, (:,:,3)=meanDose
%sliceNumsM      : (:,:,1)=maxSliceNums, (:,:,2)=minSliceNums
%
%Usage:
%   [doseShadowM, sliceNumsM] = getStructureShadowMask(rasterSegs, x, y, planC, stateS, hWaitbar)

%Get range of slices containing structure
maxSliceNum = max(rasterSegs(:,6));
minSliceNum = min(rasterSegs(:,6));

%Init storage matrices
zeroArray = zeros(y,x);
uint8Zeros = uint8(zeroArray);
maxDoses = zeroArray;
minDoses = ones(y,x)*inf;
meanDoses = zeroArray;
maxSliceNums = uint8Zeros;
minSliceNums = uint8Zeros;
meanSliceCount = zeroArray;

slices = minSliceNum:maxSliceNum;

%Iterate over all slices with structure
for i=slices
    if exist('hWaitbar')
        waitbar((i-minSliceNum)/(maxSliceNum-minSliceNum),hWaitbar);
    end
    
    %Inflate this slice's structure mask from rasterSegments 
    oneSlicesSegs = rasterSegs(find(rasterSegs(:,6) == i),:);
    [sliceMask, sliceValues] = rasterToMask(oneSlicesSegs, x, y);        

    %Get the dose contained within the mask, at CT resolution
    dose = getDoseOnCTSlice(i, stateS.doseSet, planC, stateS, sliceMask);
    
    %Update maxDoses array and maxSliceNums
    oldMaxDoses = maxDoses;
    maxDoses(sliceMask) = max(dose(sliceMask), maxDoses(sliceMask));    
    newDoseIndices = logical(uint8(zeros(y,x)));
    newDoseIndices(sliceMask) = oldMaxDoses(sliceMask) ~= maxDoses(sliceMask);
    maxSliceNums(newDoseIndices) = uint8(i);
    
    %Update minDoses array and minSliceNums
    oldMinDoses = minDoses;
    minDoses(sliceMask) = min(dose(sliceMask), minDoses(sliceMask));
    newDoseIndices = logical(uint8(zeros(y,x)));
    newDoseIndices(sliceMask) = oldMinDoses(sliceMask) ~= minDoses(sliceMask);
    minSliceNums(newDoseIndices) = uint8(i);
    
    %Update meanDoses array and meanSliceCount
    meanDoses(sliceMask) = meanDoses(sliceMask) + dose(sliceMask);
    meanSliceCount(sliceMask) = meanSliceCount(sliceMask) + 1;
end
meanSliceCount(meanSliceCount == 0) = 1;

%Get final mean
meanDoses = meanDoses ./ meanSliceCount;
minDoses(minDoses == inf) = 0;
meanDoses(meanDoses == inf) = 0;

%Build matrices to be returned
doseShadowM(:,:,1) = maxDoses;
doseShadowM(:,:,2) = minDoses;
doseShadowM(:,:,3) = meanDoses;

sliceNumsM(:,:,1) = maxSliceNums;
sliceNumsM(:,:,2) = minSliceNums;
sliceNumsM(:,:,3) = uint8(meanSliceCount);