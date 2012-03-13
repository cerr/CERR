function [struct3D slice]= getStruct3DMaskedData(structNum)
% Returns the 3D mask of structure the only difference being that the
% values inside the mask are the scan values instead of 1.
% 
% written DK 
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

global planC
indexS = planC{end};

scanNum = getStructureAssociatedScan(structNum);

[rStructValsV, cStructValsV, sStructValsV] = getUniformStr(structNum);

slice = unique(sStructValsV);

mask3D = getUniformStr(structNum);

struct3D = mask3D(:,:,slice);

clear mask3D

scanArray = getScanArray(planC{indexS.scan}(scanNum));

scanArray = scanArray(:,:,slice);

struct3D = struct3D.*scanArray;

clear scanArray