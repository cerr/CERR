function [edgeS, maskDown3D] = getSurface(structNumV, marginV, xyDownsampleIndex, planC)
%"getSurface"
%   Get all the surface points of a a composite structure defined by the 
%   structures given in structNumV, with margins epanded in 3D according to
%   marginV.  The iV, jV, kV index vectors give all the surface points with
%   respect to the uniformized CT scan.
%
%JOD, 14 Nov 03.
%JRA, 27 Mar 05.
%
%Usage:
%   [iEdgeV,jEdgeV,kEdgeV] = getSurface(structNumV,marginV, xyDownsampleIndex)
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
    global planC
end
indexS = planC{end};

global stateS

if any(marginV ~= marginV(1))
  error('Currently only supports the same PB margin around each target.')
end
margin = marginV(1);

scanNum = getStructureAssociatedScan(structNumV(1));
CTUniformInfoS = planC{indexS.scan}(scanNum).uniformScanInfo;

xOffset = CTUniformInfoS.xOffset;
yOffset = CTUniformInfoS.yOffset;

sliceThickness = CTUniformInfoS.sliceThickness;

delta_xy = CTUniformInfoS.grid1Units;

%-----------build composite target volume---------------------%

mask3D = getUniformStr(structNumV(1));

SZ=size(mask3D);

maskDown3D = logical(getDownsample3(mask3D, xyDownsampleIndex, 1));

clear mask3D

S = size(maskDown3D);

len = length(structNumV);

for i = 2 : len

  maskSingle = getUniformStr(structNumV(i));

  mask3D = maskSingle; clear maskSingle;

  tmp3D = logical(getDownsample3(mask3D, xyDownsampleIndex, 1));

  clear mask3D

  maskDown3D = tmp3D | maskDown3D;

end

% II.  Get surface points from target volume

edge = [0 0 0; 0 1 0; 0 0 0];
edge(:,:,2) = [0 1 0; 1 1 1; 0 1 0];
edge(:,:,3) = [0 0 0; 0 1 0; 0 0 0];
edge = edge/7;

surfPoints = getSurfacePoints(maskDown3D);
edge3D = repmat(logical(0), size(maskDown3D));
for i=1:size(surfPoints,1)
   edge3D(surfPoints(i,1),surfPoints(i,2), surfPoints(i,3)) = 1;
end
  
%Expand margin using convolution
%Create margin ball:

c1 = ceil(margin/delta_xy);
c2 = ceil(margin/delta_xy);
c3 = ceil(margin/sliceThickness);

[uM,vM,wM] = meshgrid(- c1 : c1, -c2 : c2, - c3 : c3);

xM = uM * delta_xy;
yM = vM * delta_xy;
zM = wM * sliceThickness;

rM = (xM.^2 + yM.^2 + zM.^2).^0.5;

ball = [rM <= margin];

[iBallV,jBallV,kBallV] = find3d(ball);

sR = size(rM);

deltaV = (sR - 1)/2 +1;

onesV = repmat(logical(1), [1,length(iBallV)]);

[iV,jV,kV] = find3d(edge3D);

sV = size(maskDown3D);

ind_surfV = sub2ind(sV,iV,jV,kV);

ball_offsetV = (iBallV - deltaV(1)) + sV(1) * (jBallV - deltaV(2)) + sV(1) * sV(2) * (kBallV - deltaV(3));

for i = 1 : length(ind_surfV) %put ones in

  total_indV = ind_surfV(i) + ball_offsetV;

  total_indV = clip(total_indV,1,prod(sV),'limits');

  maskDown3D(total_indV) = onesV;

end

%Find new edge
surfPoints = getSurfacePoints(maskDown3D);

edgeS.rows   = surfPoints(:,1);%iV;
edgeS.cols   = surfPoints(:,2);%jV;
edgeS.slices = surfPoints(:,3);%kV;