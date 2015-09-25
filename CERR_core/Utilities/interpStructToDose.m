function [newStr, planC] = interpStructToDose(strNum, doseNum, planC);
%"interpStructToDose"
%   Structure interpolated to grid of the doseArray.
%
%Usage:
%   [newStr] = interpStructToDose(strNum, doseNum, planC);
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

if ~exist('planC')
    global planC;
end
indexS = planC{end};  

%Get scanset associated with structure.
scanNum = getStructureAssociatedScan(strNum);

%Get that scanset's uniformized xyz vals.
[xVU, yVU, zVU]  = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
[xVD, yVD, zVD]         = getDoseXYZVals(planC{indexS.dose}(doseNum));
[xVDM, yVDM, zVDM]      = meshgrid(xVD, yVD, zVD);

%Get the mask registered to the uniformized scan.
maskM = getUniformStr(strNum);


% Use this if you want to avoid rounding errors
%deltax = round((xVU(2) - xVU(1))*10000)/10000;
%deltay = round((yVU(2) - yVU(1))*10000)/10000;
%newStr = nnfinterp3(xVDM(:), yVDM(:), zVDM(:), maskM, [xVU(1) deltax xVU(end)], [yVU(1) deltay yVU(end)], zVU, 0);


%Interpolate using fast nearest neighbor interpolation to the dose grid.
newStr = nnfinterp3(xVDM(:), yVDM(:), zVDM(:), maskM, [xVU(1) xVU(2)-xVU(1) xVU(end)], [yVU(1) yVU(2)-yVU(1) yVU(end)], zVU, 0);

%Reshape the output to match the dosegrid's dimensions.
newStr = reshape(newStr, [length(yVD), length(xVD), length(zVD)]);

%Cast as logicals.
newStr = logical(newStr);