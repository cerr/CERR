function [maskDown3D] = getSurfaceContract(structNumV,marginV, xyDownsampleIndex)
%function [iEdgeV,jEdgeV,kEdgeV] = getSurfaceContract(structNumV,marginV, xyDownsampleIndex)
%Get all the surface points of a a composite structure defined by the 
%structures given in structNumV, with margins shrunk in 3D according to
%marginV.  The iV, jV, kV index vectors give all the surface points with
%respect to the uniformized CT scan.
%JOD, 14 November 03.
%LM: APA, 9/10/07, based on getSurfaceExpand by JOD.
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

%obtain associated scanNum for structures. It is assumed that all the
%structures are associated to same scan (which is checked in IMRTP.m)
scanNumV = getStructureAssociatedScan(structNumV);
scanNum = scanNumV(1);

if any(marginV ~= marginV(1))
  error('Currently only supports the same PB margin around each target.')
end
margin = marginV(1);

CTUniformInfoS = planC{indexS.scan}(scanNum).uniformScanInfo;

xOffset = CTUniformInfoS.xOffset;
yOffset = CTUniformInfoS.yOffset;

sliceThickness = CTUniformInfoS.sliceThickness;

delta_xy = CTUniformInfoS.grid1Units;

%-----------build composite target volume---------------------%
clear planC;

maskSingle = getUniformStr(structNumV(1));

mask3D = double(maskSingle);

SZ=size(mask3D);

SZ=size(maskSingle);

maskDown3D = logical(getDownsample3(mask3D, xyDownsampleIndex, 1));

clear mask3D;

clear maskSingle;

global planC;

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

% edge3D = convn(maskDown3D,edge,'same');
% 
% edge3D = [edge3D < 0.999] & maskDown3D;

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

onesV = 0*repmat(logical(1), [1,length(iBallV)]); %APA

[iV,jV,kV] = find3d(edge3D);

sV = size(maskDown3D);

ind_surfV = sub2ind(sV,iV,jV,kV);

ball_offsetV = (iBallV - deltaV(1)) + sV(1) * (jBallV - deltaV(2)) + sV(1) * sV(2) * (kBallV - deltaV(3));

for i = 1 : length(ind_surfV) %put ones in

  total_indV = ind_surfV(i) - ball_offsetV; %APA

  total_indV = clip(total_indV,1,prod(sV),'limits');

  maskDown3D(total_indV) = onesV;

end