function [distV, volsV] = getDLH(doseNum, structNum, cutoff, operator, planC)
%function [distV, volsV, binWidth] = getDLH(doseNum, structNum, cutoff, operator, planC)
%
%"getDVH"
%   Returns DLH vectors for a specified structure, dose, dose-cutoff and >< operator
%   distV is a vector of distance of voxels in the structure from its surface
%   volsV is the volumes of the corresponding voxels in distV.
%
%APA, 06/17/2009
%
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

indexS  = planC{end};
optS    = planC{indexS.CERROptions};

%Get the scan number associated with the requested structure.
[scanSet, relStructNum] = getStructureAssociatedScan(structNum, planC);

ROIImageSize = [planC{indexS.scan}(scanSet).scanInfo(1).sizeOfDimension1  planC{indexS.scan}(scanSet).scanInfo(1).sizeOfDimension2];

deltaY = planC{indexS.scan}(scanSet).scanInfo(1).grid1Units;

%Get raster segments for structure.
[segmentsM, planC, isError] = getRasterSegments(structNum, planC);

if isempty(segmentsM)
    isError = 1;
end
numSegs = size(segmentsM,1);

%Relative sampling of ROI voxels in this place, compared to CT spacing.
%Set when rasterSegments are generated (usually on import).
sampleRate = optS.ROISampleRate;

%Sample the rows
indFullV =  1 : numSegs;
if sampleRate ~= 1
    rV = 1 : length(indFullV);
    rV([rem(rV+sampleRate-1,sampleRate)~=0]) = [];
    indFullV = rV;
end

%Get coordinates of surface points
UniformMask3M = getUniformStr(structNum);
surfPointsM = getSurfacePoints(UniformMask3M);
[xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanSet));
xSurfaceV = xVals(surfPointsM(:,2));
ySurfaceV = yVals(surfPointsM(:,1));
zSurfaceV = zVals(surfPointsM(:,3));

%Get transformation matrices for both dose and structure.
transMDose    = getTransM('dose', doseNum, planC);
if isempty(transMDose)
    transMDose = eye(4);
end
transMStruct  = getTransM('struct', structNum, planC);
if isempty(transMStruct)
    transMStruct = eye(4);
end
transM = inv(transMDose) * transMStruct;
[xSurfaceV, ySurfaceV, zSurfaceV] = applyTransM(transM, xSurfaceV, ySurfaceV, zSurfaceV);

xyzSurfaceM = [xSurfaceV(:) ySurfaceV(:) zSurfaceV(:)]';

%Block process to avoid swamping on large structures
DVHBlockSize = 50;

blocks = ceil(length(indFullV)/DVHBlockSize);
volsV  = [];
distV = [];

start = 1;
hWait = waitbar(0,'Computing DLH...');

for b = 1 : blocks

    waitbar(b/blocks,hWait)

    %Build the interpolation points matrix

    dummy = zeros(1,DVHBlockSize * ROIImageSize(1));
    x1V = dummy;
    y1V = dummy;
    z1V = dummy;
    volsSectionV =  dummy;

    if start+DVHBlockSize > length(indFullV)
        stop = length(indFullV);
    else
        stop = start + DVHBlockSize - 1;
    end

    indV = indFullV(start:stop);

    mark = 1;
    for i = indV

        tmpV = segmentsM(i,1:10);
        delta = tmpV(5) * sampleRate;
        xV = tmpV(3): delta : tmpV(4);
        len = length(xV);
        rangeV = ones(1,len);
        yV = tmpV(2) * rangeV;
        zV = tmpV(1) * rangeV;
        sliceThickness = tmpV(10);
        %v = delta^2 * sliceThickness;
        v = delta * (deltaY*sampleRate) * sliceThickness;
        x1V(mark : mark + len - 1) = xV;
        y1V(mark : mark + len - 1) = yV;
        z1V(mark : mark + len - 1) = zV;
        volsSectionV(mark : mark + len - 1) = v;
        mark = mark + len;

    end

    %cut unused matrix elements
    x1V = x1V(1:mark-1);
    y1V = y1V(1:mark-1);
    z1V = z1V(1:mark-1);
    volsSectionV = volsSectionV(1:mark-1);

    if ~isempty(transMDose)
        [x1V, y1V, z1V] = applyTransM(transM, x1V, y1V, z1V);
    end    

    %Obtain Dose
    dosesSectionV = getDoseAt(doseNum, x1V, y1V, z1V, planC);
    if operator == 1
        dosesSectionV = dosesSectionV <= cutoff;
    else
        dosesSectionV = dosesSectionV >= cutoff;
    end

    %Compute Distance to surface
    indComputeV = find(dosesSectionV);
    distSectionV = 0*dosesSectionV;
    if ~isempty(indComputeV)
        x1V = x1V(:);
        y1V = y1V(:);
        z1V = z1V(:);
        distSectionM = sepsq([x1V(indComputeV) y1V(indComputeV) z1V(indComputeV)]', xyzSurfaceM);
        distSectionV(indComputeV) = min(distSectionM,[],2);
        distSectionV(indComputeV) = (distSectionV(indComputeV)).^0.5;
    end
    distV  = [distV, distSectionV(:)'];
    volsSectionV = volsSectionV.*dosesSectionV;
    volsV  = [volsV, volsSectionV(:)'];

    start = stop + 1;

end

close(hWait)

[distV, indSortV] = sort(distV);
volsV = volsV(indSortV);

%volsV = volsV * sampleRate^2;  %must account for sampling rate!
