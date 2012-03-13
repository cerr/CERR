function [x,y,z] = doseCOM(doseStruct)
%"doseCOM"
%   Find [x,y,z] center of mass of dose contained in doseStruct.  Non
%   uniform slice width is taken into consideration.
%
%   doseStruct is planC{indexS.dose}(doseNum) where doseNum is the number
%   of the desired dose center of mass.
%
%JRA 3/12/04
%
%Usage:
%   function [x,y,z] = doseCOM(doseStruct)
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

[xVals, yVals, zVals] = getDoseXYZVals(doseStruct);

dA = getDoseArray(doseStruct);

[xMesh, yMesh] = meshgrid(xVals, yVals);

for i=1:size(dA, 3);
    slice = dA(:,:,i);
    %Weighted mesh.
    wX = xMesh .* slice;
    wY = yMesh .* slice;        
    sliceDose(i) = sum(slice(:));
    if sliceDose(i) == 0
        x(i) = 0;
        y(i) = 0;
    else
        x(i) = sum(wX(:)) / sliceDose(i);
        y(i) = sum(wY(:)) / sliceDose(i);
    end
end

%Get voxel thickness at each slice.
zDiff = diff(zVals);
dividers = [zVals(1)-zDiff(1)/2 zDiff/2 + zVals(1:end-1) zVals(end)+zDiff(end)/2];
voxThickness = diff(dividers);
totalHeight = sum(voxThickness);

totalDose = sum(sliceDose);
%Weight x,y,z values by dose on that slice/voxelThickness.
x = sum(x     .* sliceDose / voxThickness) / totalDose * totalHeight;
y = sum(y     .* sliceDose / voxThickness) / totalDose * totalHeight;
z = sum(zVals .* sliceDose / voxThickness) / totalDose * totalHeight;