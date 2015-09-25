function [uniformScan, firstSliceZValue] = scanUniformize(scanStruct, scanArray, scanInfo, dim3Spacing, tMin, tMax, keepSlice, optS, hBar)
%"scanUniformize"
%   Interpolates the input CT data values to a grid of values
%   uniform in the z direction (and therefore in each direction).
%   The scan in the passed scanStruct is used.
%
%   Format: Scan array input in (rows,cols,k) and output in 
%   (rows, cols, k).
%
%   keepSlice is either 'last' or 'first', depending on which 
%   slice should be kept. The uniform z-value calculations are
%   made beginning from that slice. Default value is 'first'.
%
%   note: this program updates a waitbar between the values of 
%         tMin and tMax. Suggested use is to create a waitbar 
%         before calling this function and to close it afterwards.
%
%Latest modifications:
% 14 Aug 02, V H Clark, creation
% Jan 02, JOD, added 8-bit support for reduced memory.
% 23 Apr 03, JOD, added back 16-bit support and fixed bug.
% 09 Apr 03, JOD, added hBar to parameter list.
% 18 Feb 05, JRA, Added scanStruct parameter for multiscan support.
%
%Usage:
%   function [uniformScan, firstSliceZValue] = scanUniformize(scanStruct, scanArray, scanInfo, dim3Spacing, tMin, tMax, keepSlice, optS, hBar)
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

if nargin < 6
  keepSlice = 'first';
end

tDelta = tMax - tMin;

%find desired z values, zi:

firstZValue = scanInfo(1).zValue;
lastZValue  = scanInfo(end).zValue;

if strcmp(keepSlice,'first')
  ziValues = [firstZValue : dim3Spacing : lastZValue];
elseif strcmp(keepSlice,'last')
  ziValuesRev = [lastZValue : -dim3Spacing : firstZValue];
  ziValues = ziValuesRev(end:-1:1);
end
firstSliceZValue = ziValues(1);

zValues  = [scanInfo(:).zValue];
helperIndex = 1;

xSize = scanInfo(1).sizeOfDimension2; %doesn't matter which slice is used as the scanInfo index -- they should all be the same.
ySize = scanInfo(1).sizeOfDimension1;
numOfElts = xSize*ySize;

xUnits = scanInfo(1).grid1Units;
yUnits = scanInfo(1).grid2Units;

xMax = xUnits*(xSize - 1);
yMax = yUnits*(ySize - 1);

if strcmpi(optS.uniformizedDataType,'uint8')
  uniformScan = zeros(ySize, xSize, length(ziValues),'uint8');
elseif strcmpi(optS.uniformizedDataType,'uint16') %assume uint16
  uniformScan = zeros(ySize, xSize, length(ziValues),'uint16');
end

if strcmpi(optS.uniformizedDataType,'uint8')
  CTMin = scanStruct.uniformScanInfo.minCTValue;
  CTMax = scanStruct.uniformScanInfo.maxCTValue;
  CTScale = 255 / (CTMax - CTMin);
elseif strcmpi(optS.uniformizedDataType,'uint16')
  CTMin = scanStruct.uniformScanInfo.minCTValue;
  CTMax = scanStruct.uniformScanInfo.maxCTValue;
  CTScale = 65535 / (CTMax - CTMin);
end

waitbar(tMin, hBar);
for k = 1 : length(ziValues)
  zi = ziValues(k);
  
  %Find nearest slices to zi value.
  [cranialSlice, caudalSlice, helperIndex] = findSurroundingSlices(zi, zValues, helperIndex);
  
  sliceWidth = abs(zValues(cranialSlice) - zValues(caudalSlice));
  if sliceWidth ~= 0
      cranialWeight = 1 - abs(zValues(cranialSlice) - zi) / sliceWidth;   
      caudalWeight  = 1 - abs(zValues(caudalSlice) - zi) / sliceWidth;
  else
      cranialWeight = 1;
      caudalWeight  = 0;
  end
  
  %Use simple linear interpolation between the two slices, by weight.
  interpSlice = double(scanArray(:,:,cranialSlice)) * cranialWeight + double(scanArray(:,:,caudalSlice)) * caudalWeight;
  if strcmpi(optS.uniformizedDataType,'uint8')
      uniformScan(:,:,k) = uint8((interpSlice - CTMin) * CTScale);
  elseif  strcmpi(optS.uniformizedDataType,'uint16')
      uniformScan(:,:,k) = uint16((interpSlice - CTMin) * CTScale);
  end  
  waitbar(tMin + (k/length(ziValues))*tDelta, hBar);
end

return

function [cranialSlice, caudalSlice, hi] = findSurroundingSlices(zi, zValues, hi)
% Find the cranial and caudal slice numbers.
% assumes that z values increase with index number.
% hi is a helper index that must be equal to or lower than the cranial slice number desired.
%    (it makes this function faster)

done = 0;
while ~done
  if (zi < zValues(hi))
    caudalSlice  = hi;
    cranialSlice = hi-1;
    hi = cranialSlice;
    done = 1;
  elseif (zValues(hi) == zi)
    cranialSlice = hi;
    caudalSlice = hi;
    done = 1;
  else
    hi = hi+1;
  end
end

return
