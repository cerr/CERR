function [Row, Col]=aapmtom(xAAPMShifted,yAAPMShifted,xOffset,yOffset,ImageWidth, voxelSizeV)
%function [Row, Col]=aapmtom(xAAPMShifted,yAAPMShifted,xOffset,yOffset,ImageWidth, voxelSizeV)
%
%Description: Convert from AAPM format coordinates to Matlab-natural matrix coords.
%The first pixel is centered at (1,1).
%
%Inputs:
%xAAPMShifted -- x coordinates in AAPM system assuming midpoint may be shifted from center
%yAAPMShifted -- y coordinates in AAPM system assuming midpoint may be shifted from center
%xOffset -- x offset from center point
%yOffset -- y offset from center point
%ImageWidth -- a single number (implying a square image) or a length-2 vector,
%              giving the numbers of rows first then columns.
%voxelSizeV -- length-2 vector giving [length on the y-side, length on the x-side]
%Output:
%Row -- A vector of row coordinates
%Col -- A vector of column coordinates
%
%Globals: None.
%
%Storage needed: Three times the size of the (x,y) input vectors.
%
%Internal parameters: None.
%
%Last modified: 5 Oct 01, JOD.
%
%Author: J. O. Deasy, deasy@radonc.wustl.edu
%
%References: W. Harms, Specifications for Tape/Network Format for Exchange of
%Treatment Planning Information, version 3.22., RTOG 3D QA Center,
%(http://rtog3dqa.wustl.edu), 1997.
%
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


if nargin == 5
  voxelSizeV = [1 1];
end

xOffset = xOffset/voxelSizeV(2);
yOffset = yOffset/voxelSizeV(1);

xAAPMShifted = xAAPMShifted/voxelSizeV(2);
yAAPMShifted = yAAPMShifted/voxelSizeV(1);

% if length(ImageWidth) == 1
% 
%   xAAPM=xAAPMShifted-xOffset;
%   yAAPM=yAAPMShifted-yOffset;
% 
%   yAAPMReshifted=yAAPM-ImageWidth/2-0.5;
%   xAAPMReshifted=xAAPM+ImageWidth/2+0.5;
% 
%   Row=-yAAPMReshifted;
%   Col=xAAPMReshifted;
% 
% else %rectangular

  xAAPM=xAAPMShifted-xOffset;
  yAAPM=yAAPMShifted-yOffset;

  yAAPMReshifted=yAAPM-ImageWidth(1)/2-0.5;
  xAAPMReshifted=xAAPM+ImageWidth(2)/2+0.5;

  Row=-yAAPMReshifted;
  Col=xAAPMReshifted;

% end
