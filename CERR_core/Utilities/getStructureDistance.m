function distance = getStructureDistance(structNum1,structNum2,planC)
%distance = getStructureDistance.m(structNum1,structNum1,planC)
%
%This function returns the distance(cm) between center of masses of
%structNum1 and structNum1
%
%APA, 10/08/2009
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

%Check if plan passed, if not use global.
if ~exist('planC')
    global planC;
end
indexS = planC{end};

%Compute centroid of structNum1
[x1,y1,z1] = calcIsocenter(structNum1, 'COM', planC);

%Compute centroid of structNum2
[x2,y2,z2] = calcIsocenter(structNum2, 'COM', planC);

%Compute distance between centroid1 and centroid2
distance = sqrt((x1-x2)^2 + (y1-y2)^2 + (z1-z2)^2);
