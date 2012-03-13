function [rowV, colV] = xytom(xV, yV, sliceNum, planC,scanNum)
%function [rowV, colV] = xytom(xV, yV, sliceNum, planC)
%Generic CERR function for converting AAPM/RTOG x,y coordinates
%into row, col coordinates on a scan/dose display.
%JOD, 2 Oct 02.
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

indexS = planC{end};
scaleX      =   planC{indexS.scan}(scanNum).scanInfo(sliceNum).grid2Units;
scaleY      =   planC{indexS.scan}(scanNum).scanInfo(sliceNum).grid1Units;
%imageWidth =   planC{indexS.scan}(scanNum).scanInfo(sliceNum).sizeOfDimension2;
imageSizeV = [planC{indexS.scan}(scanNum).scanInfo(sliceNum).sizeOfDimension1 planC{indexS.scan}(scanNum).scanInfo(sliceNum).sizeOfDimension2];


%Get any offset of CT scans to apply (neg) to structures
if ~isempty(planC{indexS.scan}(scanNum).scanInfo(1).xOffset)
  xCTOffset = planC{indexS.scan}(scanNum).scanInfo(1).xOffset;
else
  xCTOffset = 0;
end
if ~isempty(planC{indexS.scan}(scanNum).scanInfo(1).yOffset)
  yCTOffset = planC{indexS.scan}(scanNum).scanInfo(1).yOffset;
else
  yCTOffset = 0;
end

x2V = xV/scaleX;
y2V = yV/scaleY;
[rowV, colV] = aapmtom(x2V, y2V, xCTOffset/scaleX, yCTOffset/scaleY, imageSizeV);

