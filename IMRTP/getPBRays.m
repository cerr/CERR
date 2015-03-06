function [RTOGPBVectorsM, RTOGPBVectorsM_MC, PBMaskM, rowPBV, colPBV, xPosV, yPosV] = ...
          getPBRays(edgeS, sourceS, xySampleRate, scanNum)
% function [RTOGPBVectorsM, maskM, rowPBV, colPBV, xPosV, yPosV] = getPBRays(sourceS, structNumV, marginV);
%PBMaskM is a rectangular matrix representing the x (column) and y (row) values of the pencil beams.
%PBMaskM contains ones everywhere a PB beam strikes the target.
%indMaskV gives the indexed entry into maskM for each of the PBs defined on a row of RTOGPBVectorsM.
%xPosV and yPosV are the x and y vectors referring to the x and y positions (in IEC beam coords) of
%the PBMaskM matrix
%Procedure
% I.  Get RTOG i, j, k components with respect to source position (source(i).x, source(i).y, source(i).z).
% II.   Convert to gantry IEC 1217 unit vectors.
% III.  Grid and get list of Xb, YB discrete values to compute.
%      Return beamlets.x and beamlets.y.
%
%First version, JOD, 6 Oct 03.
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

global planC stateS

indexS = planC{end};

% [CTUniform3D, CTUniformInfoS] = getUniformizedCTScan;


CTUniformInfoS = planC{indexS.scan}(scanNum).uniformScanInfo;
% I.  Get downsampled 3D representation of target volume

xCTOffset = planC{indexS.scan}(scanNum).scanInfo(1).xOffset;
yCTOffset = planC{indexS.scan}(scanNum).scanInfo(1).yOffset;

%Set the gridding size by how large the PB will be at a given distance:

beamlet_delta_x = sourceS.beamletDelta_x;  %width in x dir in gantry coord system of PB projected to isodistance.
beamlet_delta_y = sourceS.beamletDelta_y;

delta_x = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units * xySampleRate;
delta_y = delta_x;

sliceThickness = planC{indexS.scan}(scanNum).uniformScanInfo.sliceThickness;

imageSize   = [planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1  planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2] ...
               /xySampleRate;
           

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
[sizeArray] = getUniformScanSize(planC{indexS.scan}(scanNum));

numSlices = sizeArray(3);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% numSlices = CTUniformInfoS.size(3);

firstZValue = planC{indexS.scan}(scanNum).uniformScanInfo.firstZValue;

zValsV = firstZValue : sliceThickness : (numSlices - 1) * sliceThickness + firstZValue;

zV = zValsV(edgeS.slices);

delta_x_orig = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
delta_y_orig = planC{indexS.scan}(scanNum).scanInfo(1).grid2Units;

downOffset_x = xCTOffset;
downOffset_y = yCTOffset;

if xySampleRate == 2
  downOffset_x = downOffset_x - 0.5 * delta_x_orig;
  downOffset_y = downOffset_y + 0.5 * delta_y_orig;
elseif xySampleRate ~= 1
  error('xySampleRate value is incorrectly set in getPBRays.  Must currently be 1 or 2.')
end

[xV, yV] = mtoaapm(edgeS.rows, edgeS.cols, imageSize, [delta_y, delta_x], [downOffset_y, downOffset_x ]);

%Convert to unit vectors directed from the source position to the voxel positions

delta_x_RTOG = (xV(:) - (sourceS.xRel + sourceS.isocenter.x));
delta_y_RTOG = (yV(:) - (sourceS.yRel + sourceS.isocenter.y));
delta_z_RTOG = (zV(:) - (sourceS.zRel + sourceS.isocenter.z));

norm_RTOG = (delta_x_RTOG.^2 + delta_y_RTOG.^2 + delta_z_RTOG.^2).^0.5;

delta_x_RTOG =  delta_x_RTOG(:)./norm_RTOG;
delta_y_RTOG =  delta_y_RTOG(:)./norm_RTOG;
delta_z_RTOG =  delta_z_RTOG(:)./norm_RTOG;

% V.   Convert to gantry IEC 1217 unit vectors.

RTOGVectorsM = [delta_x_RTOG(:), delta_y_RTOG(:), delta_z_RTOG(:)];

[gantryVectorsM] = RTOGVectors2Gantry(RTOGVectorsM, sourceS.gantryAngle);

% VI.  Grid and get list of Xb, YB discrete values to compute.
%      Return beamlets.x and beamlets.y.

%Get the positions at which the vectors strike the 'image plane' at the isodistance

normGantryV = (gantryVectorsM(:,1).^2 + gantryVectorsM(:,2).^2 + gantryVectorsM(:,3).^2).^0.5;

%These are lateral deflections at a distance from the source equal to
%sourceS.isodistance.
x_proj_plane =  (gantryVectorsM(:,1) ./ normGantryV) * sourceS.isodistance;
y_proj_plane =  (gantryVectorsM(:,2) ./ normGantryV) * sourceS.isodistance;

%Now bin into histogram of Xb and Yb values:
%First, the histogram will run from (min y, min x) to (max y, max x).
%We flip it in a final step, below.

min_col = floor(min(x_proj_plane)/beamlet_delta_x);
max_col = ceil(max(x_proj_plane)/beamlet_delta_x);

min_row = floor(min(y_proj_plane)/beamlet_delta_y);
max_row = ceil(max(y_proj_plane)/beamlet_delta_y);

edges_x = (min_col : max_col) * beamlet_delta_x;
edges_y = (min_row : max_row) * beamlet_delta_y;

[num_xV, x_binIndexV] = histc(x_proj_plane, edges_x);
[num_yV, y_binIndexV] = histc(y_proj_plane, edges_y);

n_edges_x = length(edges_x);
n_edges_y = length(edges_y);

PBMaskM = zeros(n_edges_y,n_edges_x);

%vectorize insertion
indMaskV = sub2ind(size(PBMaskM),y_binIndexV,x_binIndexV);
PBMaskM(indMaskV) = 1;  %A trick: works because we want a mask, not accumulated values.

% PBMask = flipud(PBMaskM);
% figure;
% imagesc(PBMask)
% xPosV = xscale(gca,beamlet_delta_x,-min_col); %needed as outputs
% yPosV = yscale(gca,-beamlet_delta_y,size(PBMaskM,1)-min_row);

% Fill in holes, if any
for rowNum = 1:size(PBMaskM,1)
    rowV = PBMaskM(rowNum,:);
    colStart = uint32(min(find(diff([0 rowV]) > 0)));
    colEnd = uint32(max(find(diff([rowV 0]) < 0)));
    if ~isempty(colStart)
        PBMaskM(rowNum,colStart:colEnd) = 1;
    end
end

%Get the resulting i, j, k direction vectors of the needed PBs
[rowPBV,colPBV] = find(PBMaskM);
x_proj_PB = zeros(1,length(rowPBV));
y_proj_PB = zeros(1,length(rowPBV));

for i = 1 : length(rowPBV)

  x_proj_PB(i) = edges_x(colPBV(i)) + 0.5 * beamlet_delta_x;
  y_proj_PB(i) = edges_y(rowPBV(i)) + 0.5 * beamlet_delta_y;

end

xPosV = x_proj_PB;
yPosV = y_proj_PB;

gantryVectors2(:,1) = x_proj_PB(:);
gantryVectors2(:,2) = y_proj_PB(:);
gantryVectors2(:,3) = - sourceS.isodistance * ones(size(y_proj_PB(:)));

normGantry = (gantryVectors2(:,1).^2 + gantryVectors2(:,2).^2 + gantryVectors2(:,3).^2).^0.5;

normRep = repmat(normGantry,1,3);

gantryVectors2N = gantryVectors2;

gantryVectors2 = gantryVectors2./normRep;



[RTOGPBVectorsM_MC] = gantry2RTOGVectors(gantryVectors2N, sourceS.gantryAngle,sourceS.couchAngle);

[RTOGPBVectorsM] = gantry2RTOGVectors(gantryVectors2, sourceS.gantryAngle,sourceS.couchAngle);

%-----------fini---------------------%