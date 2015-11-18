function [xVals, yVals, zVals] = getDeformXYZVals(deformStruct)
%"getDeformXYZVals"
%   Returns the x, y, and z values of the cols, rows, and slices of the
%   passed deformStruct.  
%
%   REMINDER: These x,y,z values are the coordinates of the MIDDLE of the
%   voxels of the scan.  They are not the coordinates of the dividers
%   between the voxels.
%
%
% xVals yVals zVals : x,y,z Values for scan deformation grid.
%
% Usage:
%   function [xVals, yVals, zVals] = getDeformXYZVals(deformStruct)
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

sizeDim1 = double(deformStruct.gridDimensions(2))-1;
sizeDim2 = double(deformStruct.gridDimensions(1))-1;
sizeDim3 = double(deformStruct.gridDimensions(3));
zStart = deformStruct.imagePositionPatient(3);
zRes = deformStruct.gridResolution(3);
deformStruct.xOffset = double(deformStruct.xOffset);
deformStruct.yOffset = double(deformStruct.yOffset);

xVals = deformStruct.xOffset - (sizeDim2*deformStruct.gridResolution(1))/2 : deformStruct.gridResolution(1) : deformStruct.xOffset + (sizeDim2*deformStruct.gridResolution(1))/2;
yVals = fliplr(deformStruct.yOffset - (sizeDim1*deformStruct.gridResolution(2))/2 : deformStruct.gridResolution(2) : deformStruct.yOffset + (sizeDim1*deformStruct.gridResolution(2))/2);
zVals = linspace(zStart, zStart + zRes * sizeDim3, sizeDim3);
zVals = -fliplr(zVals);
