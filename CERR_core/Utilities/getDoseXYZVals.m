function [xVals, yVals, zVals] = getDoseXYZVals(doseStruct)
%"getDoseXYZVals"
%   Returns the x, y, and z values of the cols, rows, and slices of the
%   passed doseStruct's doseArray.
%
%   By JRA 12/26/03
%
%   doseStruct      : ONE planC{indexS.dose} struct.
%
% xVals yVals zVals : x,y,z Values for dose.
%
% Usage:
%   function [xVals, yVals, zVals] = getDoseXYZVals(doseStruct, slice)
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
xVals = doseStruct.coord1OFFirstPoint : doseStruct.horizontalGridInterval : (doseStruct.sizeOfDimension1-1)*doseStruct.horizontalGridInterval + doseStruct.coord1OFFirstPoint;
yVals = doseStruct.coord2OFFirstPoint : doseStruct.verticalGridInterval : (doseStruct.sizeOfDimension2-1)*doseStruct.verticalGridInterval + doseStruct.coord2OFFirstPoint;
zVals = doseStruct.zValues;