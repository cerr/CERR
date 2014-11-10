function data3M = finterp3NOMESH(xInterpV, yInterpV, zInterpV, field3M, xOrig, yOrig, zOrig)
%"finterp3NOMESHdiv
%   Provides an interface to finterp3 that does not require a meshgrid, but
%   still uses the meshgrid in order to construct slices of the final
%   matrix, using finterp3.  Since only a single slice's mesh exists at any
%   one time, this is more memory efficent than using finterp3.  
%
%   "xInterpV, yInterpV, zInterpV" are the new grid vectors specifying the co-ordinates 
%   for which the dose is interpolated
%
%   "xOrig, yOrig, zOrig" are the x,y,z verctors of the Original dose
%
%   "field3M" is the Array(dose/scan) that is to be interpolated
%   
%   "data3M" is the new Array(dose/scan) after interpolation
%   DK  Nov 09, 2005 
%Usage:
%   function data3M = finterp3NOMESH(xInterpV, yInterpV, zInterpV, field3M, xVal, yVal, zVal)
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


%Mesh x,y since they are constant.
[xMesh, yMesh] = meshgrid(xInterpV, yInterpV);

%Make zMesh be all ones, to be multiplied by a zVal for each slice.
zMesh = ones(size(xMesh));

%Initialize the output variable.
data3M = repmat(uint16(zeros),[length(yInterpV), length(xInterpV), length(zInterpV)]);

%Convert x,y orig to [start delta end] format.
xOrig = [xOrig(1)-1e-3 xOrig(2)-xOrig(1) xOrig(end)+1e-3];
yOrig = [yOrig(1)+1e-3 yOrig(2)-yOrig(1) yOrig(end)-1e-3];

%Leave zOrig alone, it needs to be in vector format for finterp3.


%Iterate over requested Z values and interpolate slice for each Z.
for sliceNum = 1:length(zInterpV)
    data3M(:,:,sliceNum) = finterp3(xMesh, yMesh, zMesh*zInterpV(sliceNum), field3M, xOrig, yOrig, zOrig);
end
data3M(isnan(data3M))=0;
data3M = double(data3M);
clear xInterpV yInterpV zInterpV field3M xOrig yOrig zOrig