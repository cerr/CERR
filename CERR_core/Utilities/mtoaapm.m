function [xAAPM, yAAPM]=mtoaapm(Row, Col, Dims, gridUnits, offset)
%function [xAAPM, yAAPM]=mtoaapm(Row,Col,Dims)  OR (Row,Col,Dims,gridUnits,offset)
%Description: Convert from Matlab-natural matrix coordinates to AAPM format
%coordinates (with origin at the center of the image).
%
%Inputs:
%Row -- A vector of row coordinates
%Col -- A vector of column coordinates
%Dims -- A length-2 vector, giving the numbers of rows first then columns.
%gridUnits -- gives grid units on [y side, x side]
%offset -- gives offset on [y side, x side]
%
%Outputs:
%xAAPM -- x coordinates in AAPM system assuming x = 0 is the midpoint.  (unless offset is provided)
%yAAPM -- y coordinates in AAPM system assuming y = 0 is the midpoint.  (unless offset is provided)
%
%Globals: None.
%
%Storage needed: Twice the size of the (x,y) input vectors.
%
%Internal parameters: None.
%
%Last modified: 5 Oct 01, JOD.
%              19 Jul 02, VHC.  (added offset capability) 
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

yAAPMShifted=double(-double(Row)+Dims(1));  % APA: Do double(Row) since 0 is returned for uint16.
xAAPMShifted=double(Col);

yOffset=Dims(1)/2-0.5;
xOffset=Dims(2)/2+0.5;

xAAPM=xAAPMShifted-xOffset;
yAAPM=yAAPMShifted-yOffset;

if nargin > 3
  xAAPM = xAAPM*gridUnits(2)+offset(2);
  yAAPM = yAAPM*gridUnits(1)+offset(1);
end
