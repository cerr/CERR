function planC = reSliceDose(doseNum,dSag,dCor,dTrans,sincFlag,overWriteLastDose,planC)
%function planC = reSliceDose(doseNum,dSag,dCor,dTrans,sincFlag,planC)
%
%This function re-slices the dose doseNum according to resolution dSag,dCor,dTrans
%INPUT: doseNum: Dose Index (1 if only one dose is present)
%       dSag     : Slice spacing in Sagittal direction
%       dCor     : Slice spacing in Coronal direction
%       dTrans   : Slice spacing in Transverse direction
%       sincFlag : Apply sinc sampling
%       planC    : Optional input
%
%EXAMPLE:
%       global planC
%       doseNum = 1;
%       dSag=0.25; dCor=0.25; dTrans=0.4;sincFlag=0;
%       planC = reSliceDose(doseNum,dSag,dCor,dTrans,sincFlag,planC);
%
%APA, 03/17/2020
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

% Filter out dose < 0.01Gy
doseArray3M = planC{indexS.dose}(doseNum).doseArray;
[rMin,rMax,cMin,cMax,sMin,sMax] = compute_boundingbox(doseArray3M > 0.01);


[xVals, yVals, zVals] = getDoseXYZVals(planC{indexS.dose}(doseNum));
if numel(dSag) == 1 && numel(dCor) == 1 && numel(dTrans) == 1
    newZVals = zVals(sMin):dTrans:zVals(sMax);
    newXVals = xVals(cMin):dCor:xVals(cMax);
    newYVals = yVals(rMin):-abs(dSag):yVals(rMax);
else
    newZVals = dTrans;
    newXVals = dCor;
    newYVals = dSag;
end

%Store transformation to be applied later
transM = planC{indexS.dose}(doseNum).transM;

numCols = length(newXVals);
numRows = length(newYVals);
numSlcs = length(newZVals);

% Sinc upsample
if sincFlag
    newDoseArray = imresize3(doseArray3M,[numRows numCols numSlcs],'method','lanczos3');
    %newScanArray = fft_upsample3d(scanArray3M,[numRows numCols numSlcs]);

else
    [xInterpM, yInterpM, zInterpM] = meshgrid(newXVals,newYVals,newZVals);
    xInterpV = xInterpM(:);
    yInterpV = yInterpM(:);
    zInterpV = zInterpM(:);
    OOBV = 0;
    xFiledV = [xVals(1), xVals(2)-xVals(1), xVals(end)];
    yFiledV = [yVals(end), yVals(1)-yVals(2), yVals(1)];
    doseInterpV = finterp3(xInterpV, yInterpV, zInterpV, ...
        flip(doseArray3M,1), xFiledV, yFiledV, zVals, OOBV);
    newDoseArray = reshape(doseInterpV,numRows,numCols,numSlcs);
end

% Get DICOMHeader for the original dose
dcmHeaderS = planC{indexS.dose}(doseNum).DICOMHeaders;
if ~isempty(dcmHeaderS)
    dcmHeaderS.PixelSpacing = [];
    dcmHeaderS.ImagePositionPatient = [];
    dcmHeaderS.ImageOrientationPatient = [];
    dcmHeaderS.GridFrameOffsetVector = [];
    dcmHeaderS.Rows = [];
    dcmHeaderS.Columns = [];
    dcmHeaderS.SliceThickness = [];
end

% Create new dose distribution
regParamsS.horizontalGridInterval = dCor; %(x voxel width)
regParamsS.verticalGridInterval   = -abs(dSag); %(y voxel width)
regParamsS.coord1OFFirstPoint     = newXVals(1); %(x value of center of upper left voxel on all slices)
regParamsS.coord2OFFirstPoint     = newYVals(1); %(y value of center of upper left voxel on all slices
regParamsS.zValues                = newZVals; %(z values of all slices)

doseError = [];
fractionGroupID = planC{indexS.dose}(doseNum).fractionGroupID;
doseEdition = planC{indexS.dose}(doseNum).doseEdition;
description = planC{indexS.dose}(doseNum).doseDescription;
register = [];
assocScanUID = planC{indexS.dose}(doseNum).assocScanUID;
planC = dose2CERR(newDoseArray,doseError,fractionGroupID,...
    doseEdition,description,register,regParamsS,...
    overWriteLastDose,assocScanUID,planC);


planC{indexS.dose}(end).DICOMHeaders = dcmHeaderS;


