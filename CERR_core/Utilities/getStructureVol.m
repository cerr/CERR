function [structVol, planC] = getStructureVol(structNum,planC)
% getStructureVol
% This function returns the abslute volume of a structure. Can be accessed 
% from MATLAB command line or from CERR command. 
% 
% Created DK 
% Usage
% structVol = getStructureVol(structNum)
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
optS    = planC{indexS.CERROptions};

%Get the scan number associated with the requested structure.
scanSet = getStructureAssociatedScan(structNum, planC);

deltaY = planC{indexS.scan}(scanSet).scanInfo(1).grid1Units;

ROIImageSize = [planC{indexS.scan}(scanSet).scanInfo(1).sizeOfDimension1  planC{indexS.scan}(scanSet).scanInfo(1).sizeOfDimension2];

%Get raster segments for structure.
[segmentsM, planC, isError] = getRasterSegments(structNum, planC);
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

%Block process to avoid swamping on large structures
if isfield(optS, 'DVHBlockSize') & ~isempty(optS.DVHBlockSize)
    DVHBlockSize = optS.DVHBlockSize;
else
    DVHBlockSize = 5000;
end

blocks = ceil(length(indFullV)/DVHBlockSize);
volsV  = [];
scansV = [];

start = 1;

for b = 1 : blocks

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

    %Get transformation matrices for both scan and structure.
    transMScan    = getTransM('scan', scanSet, planC);
    transMStruct  = getTransM('struct', structNum, planC);

    %Forward transform the structure's coordinates.
    if ~isempty(transMStruct)
        [x1V, y1V, z1V] = applyTransM(transMStruct, x1V, y1V, z1V);
    end

    %Back transform the coordinates into the scans' coordinate system.
    if ~isempty(transMScan)
        [x1V, y1V, z1V] = applyTransM(inv(transMScan), x1V, y1V, z1V);
    end

    %Interpolate.
    [scansSectionV] = getScanAt(scanSet, x1V, y1V, z1V, planC);

    scansV = [scansV, scansSectionV];
    volsV  = [volsV, volsSectionV];

    start = stop + 1;

end

volsV = volsV * sampleRate^2;  %must account for sampling rate!
structVol = sum(sum(volsV));