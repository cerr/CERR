function [CTTraceS, RTOGPBVectorsM, RTOGPBVectorsM_MC, PBMaskM, rowPBV, colPBV, xPBPosV, yPBPosV] = ...
   getPBRayData(edgeS, sourceS, numSamplePts, xySampleRate, scanNum)
%JOD
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

water = 1000; %Assumes water equals 1000.

%-----------Get CT scan---------------------%

native = 1;
[CTUniform3D, CTUniformInfoS] = getUniformizedCTScan(native,scanNum);

xOffset = CTUniformInfoS.xOffset;
yOffset = CTUniformInfoS.yOffset;

%-----------Fix source characteristics---------------------%

orgV   = [sourceS.isocenter.x, sourceS.isocenter.y, sourceS.isocenter.z];

%-----------Get ray parameters---------------------%

[RTOGPBVectorsM, RTOGPBVectorsM_MC, PBMaskM, rowPBV, colPBV, xPBPosV, yPBPosV] = ...
      getPBRays(edgeS, sourceS, xySampleRate, scanNum);

rayLength = 500;  %in cm.  This is the length of the rays which are passed
                  %through the CT matrix to determine cumulative CT densities.

numSlices = size(CTUniform3D,3);

zFirst = CTUniformInfoS.firstZValue;

sliceThickness = CTUniformInfoS.sliceThickness;

%minBox an maxBox containt coordinates of the corners of the CT box as used
%by the ray intersection routine.

maxBoxS.z = (numSlices - 1) * sliceThickness + zFirst + sliceThickness/2;

minBoxS.z = zFirst - sliceThickness/2;

delta_xy = CTUniformInfoS.grid1Units;

imageWidth = CTUniformInfoS.size(2);
imageHeight = CTUniformInfoS.size(1);

minBoxS.x = - imageWidth/2 * delta_xy + xOffset;
maxBoxS.x =   imageWidth/2 * delta_xy + xOffset;

minBoxS.y = - imageHeight/2 * delta_xy + yOffset;
maxBoxS.y =   imageHeight/2 * delta_xy + yOffset;

% imageWidth = CTUniformInfoS.sizeOfDimension1;

CTTraceS = struct('CTNumsRay',[],'CTCumNumsRay',[],'distSamplePts',[]);

for i = 1 : size(RTOGPBVectorsM,1)

  rayDeltaS.x = RTOGPBVectorsM(i,1) * rayLength;
  rayDeltaS.y = RTOGPBVectorsM(i,2) * rayLength;
  rayDeltaS.z = RTOGPBVectorsM(i,3) * rayLength;

  %are the components of the ray's direction and maximum length.

  deltaV = [rayDeltaS.x, rayDeltaS.y, rayDeltaS.z];

  t_entrance = rayBoxIntersection(sourceS,rayDeltaS,minBoxS,maxBoxS);

  %The entrance point is therefore
  entranceV = orgV + t_entrance * deltaV;

  %Reflect to find exit point (assume length of ray is long enough that ray does exit):

  if t_entrance ~= -1

    %find exit point
    %get end of ray
    rayOrgS2.xRel = sourceS.xRel + rayDeltaS.x;  %reflected source positions
    rayOrgS2.yRel = sourceS.yRel + rayDeltaS.y;
    rayOrgS2.zRel = sourceS.zRel + rayDeltaS.z;

    rayDeltaS2.x = - rayDeltaS.x;
    rayDeltaS2.y = - rayDeltaS.y;
    rayDeltaS2.z = - rayDeltaS.z;

    rayOrgS2.isocenter = sourceS.isocenter;

    t = rayBoxIntersection(rayOrgS2,rayDeltaS2,minBoxS,maxBoxS);

    t_exit = 1 - t;

    exitV = orgV + t_exit * deltaV;

else
    error('PB Ray does not intersect CT scan.');
end

  %Now produce a set of sampling points between the entrance and the exit

  nV = 1 : numSamplePts;

  delta_t  = (t_exit - t_entrance)/(numSamplePts - 1);

  tV = t_entrance + (nV - 1) * delta_t;

  CTTraceS(i).distSamplePts = tV * sum(deltaV.^2).^0.5;

  sampleV.x =  sourceS.xRel + tV * deltaV(1);

  sampleV.y =  sourceS.yRel + tV * deltaV(2);

  sampleV.z =  sourceS.zRel + tV * deltaV(3);

  sampleRTOGV.x = sampleV.x + sourceS.isocenter.x;
  sampleRTOGV.y = sampleV.y + sourceS.isocenter.y;
  sampleRTOGV.z = sampleV.z + sourceS.isocenter.z;

  %---------Sample CT densities----------%

  %To go from sample points in RTOG system to CT densities, we convert as follows:

  %What is the slice number?
  sliceV = 1 + (sampleRTOGV.z - zFirst)/sliceThickness;

  %Now do 3-D interpolation:
  zFieldV = [minBoxS.z + 0.5 * sliceThickness, sliceThickness, maxBoxS.z - 0.5 * sliceThickness];
  xFieldV = [minBoxS.x + 0.5 * delta_xy, delta_xy, maxBoxS.x - 0.5 * delta_xy];
  yFieldV = [minBoxS.y + 0.5 * delta_xy, delta_xy, maxBoxS.y - 0.5 * delta_xy];

  CTNumsV = getScanAt(scanNum, sampleRTOGV.x, sampleRTOGV.y, sampleRTOGV.z, planC);

  CTTraceS(i).densityRay = delta_t * norm(deltaV) * CTNumsV/water;
  CTTraceS(i).cumDensityRay = cumsum(CTTraceS(i).densityRay);  %Account for sampling rate to convert to g/cm^2.

  if any(CTTraceS(i).cumDensityRay > 50)
      warning('Cumulative density ray appears to exceed maximum length.');
  end

end

%-----------fini---------------------%


















