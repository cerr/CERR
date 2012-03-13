function [dosesToCT3M] = get3DDosesNoSkin(doseSet, planC, indexS, optS)
% CZ May 04
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

z0V = planC{indexS.dose}(doseSet).zValues;

xMin = planC{indexS.dose}(doseSet).coord1OFFirstPoint;
yMax = planC{indexS.dose}(doseSet).coord2OFFirstPoint;

delta_x0 = abs(planC{indexS.dose}(doseSet).horizontalGridInterval);

delta_y0 = abs(planC{indexS.dose}(doseSet).verticalGridInterval);

dose3M = getDoseArray(planC{indexS.dose}(doseSet));

num_x = size(dose3M,2);
num_y = size(dose3M,1);

xMax = xMin + (num_x - 1) * delta_x0;
yMin = yMax - (num_y - 1) * delta_y0;

x0V = xMin + (0:num_x-1) * delta_x0;
y0V = yMax - (0:num_y-1) * delta_y0;  %reversed to agree with interp3 & meshgrid convention.

scanNum = getDoseAssociatedScan(doseSet, planC);
ROIImageSize  = size(getScanArray(planC{indexS.scan}(scanNum)));

dosesToCT3M = zeros(ROIImageSize);

segmentsM = fakeSegments(planC);

numSegs = size(segmentsM,1);

%Relative sampling of ROI voxels  compared to CT spacing.
sampleRate = 1;

%Sample the rows
indFullV =  1 : numSegs;
if sampleRate ~= 1
 rV = 1 : length(indFullV);
 rV([rem(rV+sampleRate-1,sampleRate)~=0]) = [];
 indFullV = rV;
end

%Block process to avoid swamping on large structures
DVHBlockSize = optS.DVHBlockSize;
blocks = ceil(length(indFullV)/DVHBlockSize);
rowsV = [];
colsV = [];
slicesV = [];
dosesV = [];

start = 1;

for b = 1 : blocks

  %Build the interpolation points matrix

  dummy = zeros(1,DVHBlockSize * ROIImageSize(1));
  x1V = dummy;
  y1V = dummy;
  z1V = dummy;

  sliceV = dummy;
  rowsV = dummy;
  colsV = dummy;

  if start+DVHBlockSize > length(indFullV)
    stop = length(indFullV);
  else
    stop = start + DVHBlockSize - 1;
  end

  indV = indFullV(start:stop);

  mark = 1;
  for i = indV

    tmpV = segmentsM(i,1:10);

    delta = tmpV(5) * sampleRate;
    xV = tmpV(3): delta : tmpV(4);
    len = length(xV);
    rangeV = ones(1,len);

    sliceV(mark : mark + len - 1) = tmpV(6) * rangeV;
    rowsV(mark : mark + len - 1) = tmpV(7) * rangeV;
    colsV(mark : mark + len - 1) = tmpV(8) : tmpV(9);

    yV = tmpV(2) * rangeV;
    zV = tmpV(1) * rangeV;
    sliceThickness = tmpV(10);
    v = delta^2 * sliceThickness;
    x1V(mark : mark + len - 1) = xV;
    y1V(mark : mark + len - 1) = yV;
    z1V(mark : mark + len - 1) = zV;
    mark = mark + len;

  end

  %cut unused matrix elements
  x1V = x1V(1:mark-1);
  y1V = y1V(1:mark-1);
  z1V = z1V(1:mark-1);
  sliceV = sliceV(1:mark-1);
  rowsV = rowsV(1:mark-1);
  colsV = colsV(1:mark-1);


  xFieldV = [xMin, delta_x0, xMax];
  yFieldV = [yMin, delta_y0, yMax];
  delta_z = z0V(2)-z0V(1);
  zFieldV = [min(z0V), delta_z, max(z0V)];
  [dosesV] = finterp3(x1V, y1V, z1V, dose3M, xFieldV, yFieldV, zFieldV);

  indV = sub2ind(ROIImageSize, rowsV, colsV, sliceV);
  dosesToCT3M(indV) = dosesV;

  start = stop + 1;

end


