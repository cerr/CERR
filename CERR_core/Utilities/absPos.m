function absPos = absPos(relPos, box)
%"absPos"
%Convert from relative position to absolute position in pixels, given
%x,y,w,h of box in pixels, and relPos, a series of relative positions.
%
% JRA 6/7/04
%
%Usage:
%   function pos = absPos(absPos, box)   
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

x = box(1); y = box(2);
w = box(3); h = box(4);

absPos(1) = relPos(1) * w + x;
absPos(2) = relPos(2) * h + y;
absPos(3) = relPos(3) * w;
absPos(4) = relPos(4) * h;