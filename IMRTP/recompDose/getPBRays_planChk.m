function [RTOGPBVectorsM, RTOGPBVectorsM_MC, PBMaskM, rowPBV, colPBV, xPosV, yPosV, beamlet_delta_x, beamlet_delta_y] = getPBRays_planChk(xPosV, yPosV, beamlet_delta_x, beamlet_delta_y, sourceS)
%Test Function, Remove later.
% LM: JC Dec 1, 2006
    % replace input "gA" by "sourceS", to remove the constrains of isodistance = 100; calc isodistance using sourceS
    % JC Jan 25, 2006
    % add couchAngle as a input to function gantry2RTOGVectors
    % Remove the assumption of coucnAngle == 0. 
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
    
% global planC
% indexS = planC{end};

% JC. Dec 1, 2006
% isodistance = 100;
% gantryAngle = gA;
isodistance = sourceS.isodistance;
gantryAngle = sourceS.gantryAngle;
couchAngle = sourceS.couchAngle;
collimatorAngle = sourceS.collimatorAngle;

% load PBMaskM %Includes: PBMaskM PBxV PByV
PBMaskM = [];
rowPBV = [];
colPBV = [];

% [rowPBV, colPBV] = find(PBMaskM>0);

% beamlet_delta_x = PBxV(2) - PBxV(1);
% beamlet_delta_y = PByV(2) - PByV(1);
% 
% xPosV = PBxV(colPBV) + beamlet_delta_x/2;
% yPosV = PByV(rowPBV) + beamlet_delta_y/2;

% edges_x = (min(colPBV) : max(colPBV)) * beamlet_delta_x;
% edges_y = (min(rowPBV) : max(rowPBV)) * beamlet_delta_y;

% x_proj_PB = edges_x(colPBV) + 0.5 * beamlet_delta_x;
% y_proj_PB = edges_y(rowPBV) + 0.5 * beamlet_delta_y;

% JC Apr. 06 2007
% Previous code only works for collimatorAngle = 0,
% Now implement for arbitrary collimatorAngle.
xPosV_Coll = cosdeg(collimatorAngle) * xPosV(:) - sindeg(collimatorAngle) * yPosV(:);
yPosV_Coll = sindeg(collimatorAngle) * xPosV(:) + cosdeg(collimatorAngle) * yPosV(:);

%gantryVectors2(:,1) = xPosV(:);%x_proj_PB(:);
%gantryVectors2(:,2) = yPosV(:);%y_proj_PB(:);
gantryVectors2(:,1) = xPosV_Coll(:);
gantryVectors2(:,2) = yPosV_Coll(:);

gantryVectors2(:,3) = - isodistance * ones(size(xPosV(:)));

normGantry = (gantryVectors2(:,1).^2 + gantryVectors2(:,2).^2 + gantryVectors2(:,3).^2).^0.5;

normRep = repmat(normGantry,1,3);

gantryVectors2N = gantryVectors2;

gantryVectors2 = gantryVectors2./normRep;

[RTOGPBVectorsM_MC] = gantry2RTOGVectors(gantryVectors2N, gantryAngle, couchAngle);

[RTOGPBVectorsM] = gantry2RTOGVectors(gantryVectors2, gantryAngle, couchAngle);