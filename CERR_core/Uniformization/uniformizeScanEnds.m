function [scanArraySup, scanArrayInf, uniformScanFirstZValue] = uniformizeScanEnds(scanStruct, sliceNumSup, sliceNumInf, uniformSliceThickness, tMin, tMax, optS, hBar);
%"uniformizeScanEnds"
%   Creates superior and inferior arrays with the designated thickness
%   so that they are uniform, using the sliceNumSup and sliceNumInf as
%   beginning and end indices.
%
%Latest modifications:
% 14 Aug 02, V H Clark
% 28 Jan 03, JOD, added optS to parameter lists.
% 09 May 03, JOD, added hBar to parametet list.
% 18 Feb 05, JRA, New function call to support multiple scans.
%
%Usage:
%   [scanArraySup, scanArrayInf, uniformScanFirstZValue] = uniformizeScanEnds(scanStruct, sliceNumSup, sliceNumInf, uniformSliceThickness, tMin, tMax, optS, hBar);
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

scanArraySup = [];
scanArrayInf = [];

scanArray = getScanArray(scanStruct);
scanInfo  = scanStruct.scanInfo;

calculateSup = (sliceNumSup ~= 1);
lastSlice = length(scanInfo);
calculateInf = (sliceNumInf ~= lastSlice);
tTotal = calculateSup + calculateInf;
tDelta = tMax - tMin;

if calculateSup && length(scanInfo)>1
  inputScanArraySup = scanArray(:, :, 1:sliceNumSup);
  scanInfoSup = scanInfo(1:sliceNumSup);
  [scanArraySup, uniformScanFirstZValue] = ...
      scanUniformize(scanStruct,inputScanArraySup, scanInfoSup, ...
      uniformSliceThickness, tMin, tMin+tDelta/tTotal, 'last', optS, hBar);
  scanArraySup = scanArraySup(:,:,1:end-1); %get rid of duplicate slice
else
  uniformScanFirstZValue = scanInfo(1).zValue;
end

if calculateInf && length(scanInfo)>1
  inputScanArrayInf = scanArray(:, :, sliceNumInf:lastSlice);
  scanInfoInf = scanInfo(sliceNumInf:lastSlice);
  scanArrayInf = scanUniformize(scanStruct,inputScanArrayInf,scanInfoInf, ...
      uniformSliceThickness, tMax - tDelta/tTotal, tMax, 'first', optS, hBar); %the first slice from this will be the last slice in the middle of the CT already.
  scanArrayInf = scanArrayInf(:,:,2:end); %get rid of duplicate slice
end

return
