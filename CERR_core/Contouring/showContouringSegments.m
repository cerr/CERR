function showContouringSegments(contourS,sliceNum)
%Display any segments stored in contourS for slice sliceNum.
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


global planC indexS

scale =  planC{indexS.scan}.scanInfo(sliceNum).grid1Units;

imageWidth =  planC{indexS.scan}.scanInfo(sliceNum).sizeOfDimension1;

[xCTOffset, yCTOffset] = getCTOffsets;

numSegs = contourS(sliceNum).segments;

segS = [];

for i = 1 : numSegs

  pointsM = contourS(sliceNum).segments(i).points;
  xCoords = pointsM(:,1);
  yCoords = pointsM(:,2);

  [rowV, colV] = aapmtom(xCoords/scale, yCoords/scale, xCTOffset/scale, yCTOffset/scale, imageWidth);

  rowV = [rowV; rowV(1)];
  colV = [colV; colV(1)];

  %Update contour plot
  hold on
  hPlot = plot([colV, colV(1)],[rowV, rowV(1)],'rs-')
  hold off
  segS.hPlot = hPlot;
  segS.GUI_xV = colV;
  segS.GUI_yV = rowV;
  segS.active = 0;
  set(hPlot,'markersize',4)
  set(hPlot,'userdata',segS)
  set(hPlot,'tag','newSegment')

end
