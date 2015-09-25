function min_dist = getSurfaceDistance(structNum1,structNum2,planC)
%function min_dist = getSurfaceDistance(structNum1,structNum2,planC)
%
%This function calculates minimum distance between the surfaces of two 
%structures structNum1 and structNum2. planC is an optional input argument.
%
%APA, 02/04/2010
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

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

%Set scan associations
scanNum1 = getAssociatedScan(planC{indexS.structures}(structNum1).assocScanUID, planC);
scanNum2 = getAssociatedScan(planC{indexS.structures}(structNum2).assocScanUID, planC);

%Get x,y,z coordinates of uniformized scans
[xVals1v, yVals1v, zVals1v] = getUniformScanXYZVals(planC{indexS.scan}(scanNum1));
xVals1v = xVals1v(:);
yVals1v = yVals1v(:);
zVals1v = zVals1v(:);
dx1 = abs(xVals1v(2)-xVals1v(1));
dy1 = abs(yVals1v(2)-yVals1v(1));
[xVals2v, yVals2v, zVals2v] = getUniformScanXYZVals(planC{indexS.scan}(scanNum2));
xVals2v = xVals2v(:);
yVals2v = yVals2v(:);
zVals2v = zVals2v(:);
dx2 = abs(xVals2v(2)-xVals2v(1));
dy2 = abs(yVals2v(2)-yVals2v(1));

%Get Uniformized mask for structure 1
mask3M1 = getUniformStr(structNum1, planC);

%Get surface points for structure 1
indicesM = getSurfacePoints(mask3M1);
clear mask3M1
xyzSurface1v = [xVals1v(indicesM(:,2)) yVals1v(indicesM(:,1)) zVals1v(indicesM(:,3))];

%Get Uniformized mask for structure 2
mask3M2 = getUniformStr(structNum2, planC);

%Get surface points for structure 2
indicesM = getSurfacePoints(mask3M2);
clear mask3M2
xyzSurface2v = [xVals2v(indicesM(:,2)) yVals2v(indicesM(:,1)) zVals2v(indicesM(:,3))];

%Compute minimum distance between surface points
dist_sq = sepsq(xyzSurface1v', xyzSurface2v');
clear xyzSurface1v xyzSurface2v
min_dist = sqrt(min(dist_sq(:)));

%If distance is within voxel resolution, snap it to 0
if min_dist < max([dx1,dx2,dy1,dy2])
    min_dist = 0;
end

