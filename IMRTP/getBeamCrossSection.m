function isodoseClosedContour = getBeamCrossSection()
%isodoseClosedContour50 = getBeamCrossSection()
%
%Output: isodoseClosedContour - representation of beam contour
%dimension (3xN). 1st, 2nd and 3rd row represent x, y and z-coords of the
%contour respectively. It is assumed that the ray starts at (0,0,0) and
%moves along +(ve) x-axis. If collimatorType does not match the list, an
%empty isodoseClosedContour50 is returned.
%
%APA 01/21/09
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

% Get a 10x10 section at 100cm distance. In future, these points should
% come from Leaf-sequences or beamlet-fluence map.
isodoseClosedContour(3,:) = [-10 10 10 -10 -10]/2;
isodoseClosedContour(2,:) = [-10 -10 10 10 -10]/2;
isodoseClosedContour(1,:) = [100 100 100 100 100];
return
