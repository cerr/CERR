function planC = updateStructureMatrices(planC, editStructNum, sliceNumsV)
%"updateStructureMatrices"
%    Updates uniformized data for changes in structure contours.  editStructNum
%    is the number of the structure that has changed.  sliceNumsV is an optional
%    parameter specifying which uniformized slices should be updated.  If
%    it is not included, all relevant slices are re-uniformized.
%
%WARNING: sliceNumsV input parameter is in UNIFORMIZED slices.
%WARNING: Uniformization is performed using raster segments.  Raster
%         segments must be re-generated first!
%
% Created by   : V H Clark, 22 Aug 02.
% Last Modified: JOD, 14 Oct 02.
%              : JRA, 3 Oct 03.
%              : JRA, 10 Nov 04.
%
%Usage:
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


%   planC = updateStructureMatrices(planC, editStructNum, sliceNumsV)
global stateS
indexS = planC{end};

%Figure out what relative structNum this is for the specified scanNum;
[scanNum, relStructNum] = getStructureAssociatedScan(editStructNum, planC);
[assocScansV] = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
totalStructsInScan = length(find(assocScansV == scanNum));

%Get background data on scan, uniformized data assoc. with structure.
scanInfo            = planC{indexS.scan}(scanNum).scanInfo;
sizeArray           = getUniformScanSize(planC{indexS.scan}(scanNum));
[xV, yV, zV]        = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
[xVs, yVs, zVs]     = getScanXYZVals(planC{indexS.scan}(scanNum));
% if length(zVs) == 1
%     return;
% end
CTOriginalZValues   = [scanInfo(:).zValue];
CTSliceThickness    = [scanInfo(:).sliceThickness];
CTdeltaX            = abs(xV(2) - xV(1));
CTdeltaY            = abs(yV(2) - yV(1));

%Retrieve the structure's raster segments.
[allSegmentsM, planC, isError] = getRasterSegments(editStructNum, planC);

reusableZerosM = repmat(logical(0),[sizeArray(1), sizeArray(2)]);

%Initialize structureArray and bits array if they dont exist.
if (length(planC{indexS.structureArray}) < scanNum) || (length(planC{indexS.structureArray}) >= scanNum && isempty(planC{indexS.structureArray}(scanNum).assocScanUID))
    tmp = uint16([0 0 0]);
    tmp(1,:) = [];
    planC{indexS.structureArray}(scanNum).indicesArray = tmp;
    tmp = uint8(0);
    tmp(1) = [];
    planC{indexS.structureArray}(scanNum).bitsArray = tmp;
    planC{indexS.structureArray}(scanNum).assocScanUID = planC{indexS.scan}(scanNum).scanUID;
    planC{indexS.structureArray}(scanNum).structureSetUID = createUID('STRUCTURESET');

    planC{indexS.structureArrayMore}(scanNum).indicesArray = [];
    planC{indexS.structureArrayMore}(scanNum).bitsArray = [];
    planC{indexS.structureArrayMore}(scanNum).assocScanUID = planC{indexS.scan}(scanNum).scanUID;
    planC{indexS.structureArrayMore}(scanNum).structureSetUID = createUID('STRUCTURESET');
    
    if isfield(stateS,'structSet') && isempty(stateS.structSet)
        stateS.structSet = scanNum;
    end    
end

if relStructNum <= 52
    cellNum = 1;
else
    cellNum = ceil((relStructNum-52)/8)+1;
end

%Clear old data for this structure.  If sliceNumsV is specified clear
%only those slices, otherwise clear all slices.
if exist('sliceNumsV') && ((cellNum == 1) || (cellNum-1 <= length(planC{indexS.structureArrayMore}(scanNum).indicesArray)))
    if isempty(planC{indexS.structureArray}(scanNum).indicesArray)
        optS = planC{indexS.CERROptions};
        [indicesM, structBitsM, indicesC, structBitsC] = createStructuresMatrices(planC, scanNum, 1/2, 1, optS);
        planC = storeStructuresMatrices(planC, indicesM, structBitsM, indicesC, structBitsC, scanNum);
    end
    if cellNum == 1
        tf = ismember(planC{indexS.structureArray}(scanNum).indicesArray(:,3), sliceNumsV);
        if totalStructsInScan > 32
            planC{indexS.structureArray}(scanNum).bitsArray(tf) = bitset(double(planC{indexS.structureArray}(scanNum).bitsArray(tf)), relStructNum, 0);
        elseif totalStructsInScan > 16
            planC{indexS.structureArray}(scanNum).bitsArray(tf) = bitset(uint32(planC{indexS.structureArray}(scanNum).bitsArray(tf)), relStructNum, 0);
        elseif totalStructsInScan > 8
            planC{indexS.structureArray}(scanNum).bitsArray(tf) = bitset(uint16(planC{indexS.structureArray}(scanNum).bitsArray(tf)), relStructNum, 0);
        else
            planC{indexS.structureArray}(scanNum).bitsArray(tf) = bitset(uint8(planC{indexS.structureArray}(scanNum).bitsArray(tf)), relStructNum, 0);
        end
    else
        tf = ismember(planC{indexS.structureArrayMore}(scanNum).indicesArray{cellNum-1}(:,3), sliceNumsV);
        planC{indexS.structureArrayMore}(scanNum).bitsArray{cellNum-1}(tf) = bitset(uint8(planC{indexS.structureArrayMore}(scanNum).bitsArray{cellNum-1}(tf)), relStructNum - 52 - 8*(cellNum-2), 0);
    end
elseif (cellNum == 1)
        if totalStructsInScan > 32
            planC{indexS.structureArray}(scanNum).bitsArray = bitset(double(planC{indexS.structureArray}(scanNum).bitsArray), relStructNum, 0);
        elseif totalStructsInScan > 16
            planC{indexS.structureArray}(scanNum).bitsArray = bitset(uint32(planC{indexS.structureArray}(scanNum).bitsArray), relStructNum, 0);
        elseif totalStructsInScan > 8
            planC{indexS.structureArray}(scanNum).bitsArray = bitset(uint16(planC{indexS.structureArray}(scanNum).bitsArray), relStructNum, 0);
        else
            planC{indexS.structureArray}(scanNum).bitsArray = bitset(uint8(planC{indexS.structureArray}(scanNum).bitsArray), relStructNum, 0);
        end    
elseif (cellNum-1 <= length(planC{indexS.structureArrayMore}(scanNum).indicesArray))
    planC{indexS.structureArrayMore}(scanNum).bitsArray{cellNum-1} = bitset(uint8(planC{indexS.structureArrayMore}(scanNum).bitsArray{cellNum-1}), relStructNum - 52 - 8*(cellNum-2), 0);
end

%Now we need to generate the indicesM entries for the modified structure
k = 0;
if ~isempty(allSegmentsM)
    wb = waitbar(0, ['Saving updated data for ' planC{indexS.structures}(editStructNum).structureName '...']);

    %If no predefined slice numbers were passed in...
    if ~exist('sliceNumsV')
        %Only use slice numbers bookending the raster segments' Zs
        minRasterZ = min(allSegmentsM(:,1));
        maxRasterZ = max(allSegmentsM(:,1));

        %Add a one slice buffer to cover all relevant uni. slices.
        minRasterZ = zVs(max(max(find(zVs <= minRasterZ)) - 1, 1));
        maxRasterZ = zVs(min(min(find(zVs >= maxRasterZ)) + 1, length(zVs)));

        %1 and length(zV) are included to prevent boundary errors.
        minUniSlice = max([find(zV < minRasterZ) 1]);
        maxUniSlice = min([find(zV > maxRasterZ) length(zV)]);

        sliceNumsV = minUniSlice:maxUniSlice;
    end

    %Preallocate the mask array.
    structM = repmat(reusableZerosM, [1 1 length(sliceNumsV)]);

    %Allocations to create a new cell
    allocatedSpace = 1000000;  %Length of initial indicesM & structBitsM.  This predetermined size allows for only a few, if any, preallocations total.
    allocations = 1; %keeps track of how many times the space has been allocated
    indicesM    = uint16(zeros(allocatedSpace,3));
    structBitsM = uint8(zeros(allocatedSpace,1)); %uint8
    entry = 1; %indicesM and structBitsM index counter
    lastEntry = 0;
    newCellFlag = 0;

    %Build the mask array, then add the mask to the uniform data.
    for zSliceUniformValue = zV(sliceNumsV)
        k = k+1;
        beginningEntry = entry;
        waitbar(k/length(sliceNumsV), wb);
        structSlc = findStructureMatrixForOneZSlice(allSegmentsM, zSliceUniformValue, CTOriginalZValues, CTSliceThickness, CTdeltaX, CTdeltaY, reusableZerosM);

        if ((cellNum == 1) && (isempty(planC{indexS.structureArray}(scanNum).indicesArray))) || ((cellNum > 1) && (cellNum-1 > length(planC{indexS.structureArrayMore}(scanNum).indicesArray)))
            newCellFlag = 1;
        end
        if newCellFlag %cellNum > length(planC{indexS.structureArray}(scanNum).indicesArray)
            newCellFlag = 1;
            if cellNum == 1
                structBit = bitset(double(0), relStructNum); %double
            else
                structBit = bitset(uint8(0), relStructNum - 52 - 8*(cellNum-2)); %uint8
            end

            %now create the sparse matrix array entries
            [i,j] = find(structSlc);
            if ~isempty(i) %also j
                lastEntry = entry + length(i) - 1;
                if lastEntry > allocatedSpace*allocations
                    indicesM = [indicesM; uint16(zeros(allocatedSpace,3))];
                    switch class(structBitsM)
                        case 'double'
                            structBitsM = [structBitsM; double(zeros(allocatedSpace,1))];
                        case 'uint32'
                            structBitsM = [structBitsM; uint32(zeros(allocatedSpace,1))];
                        case 'uint16'
                            structBitsM = [structBitsM; uint16(zeros(allocatedSpace,1))];
                        case 'uint8'
                            structBitsM = [structBitsM; uint8(zeros(allocatedSpace,1))];
                    end

                    allocations = allocations + 1;
                end
                indicesM(entry:lastEntry, 1) = uint16(i);
                indicesM(entry:lastEntry, 2) = uint16(j);
                indicesM(entry:lastEntry, 3) = uint16(sliceNumsV(k)); %could do this all at once at the end of each slice
                structBitsM(entry:lastEntry) = structBit;
                entry = lastEntry + 1;
            end
            endEntry = lastEntry;

            %do unique in here
            indicesToCondenseM = double(indicesM(beginningEntry:endEntry,:));

            [uniqueIndicesM, m, n] = unique(indicesToCondenseM,'rows');
            if size(uniqueIndicesM,1) ~= size(indicesToCondenseM,1) %at least one point on one structure overlaps another structure

                switch class(structBitsM)
                    case 'double'
                        uniqueStructBitsM = double(zeros(size(uniqueIndicesM,1),1));
                    case 'uint32'
                        uniqueStructBitsM = uint32(zeros(size(uniqueIndicesM,1),1));
                    case 'uint16'
                        uniqueStructBitsM = uint16(zeros(size(uniqueIndicesM,1),1));
                    case 'uint8'
                        uniqueStructBitsM = uint8(zeros(size(uniqueIndicesM,1),1));
                end

                for i = 1:length(n) %also the size of indicesToCondenseM in dim 1
                    uniqueStructBitsM(n(i)) = bitor(uniqueStructBitsM(n(i)), structBitsM(i+beginningEntry-1));
                end

                newEndEntry = beginningEntry + size(uniqueIndicesM,1) - 1;
                indicesM(beginningEntry:newEndEntry,:) = uint16(uniqueIndicesM);
                structBitsM(beginningEntry:newEndEntry) = uniqueStructBitsM;
                lastEntry = newEndEntry;
                entry = lastEntry+1; % note that there will be non-zero entries in the matrix after the entry index which are now irrelevant and will be written over or deleted later.
            end            
            
        end
        structM(:,:,k) = logical(structSlc);
    end
    if ~newCellFlag
        planC = uniformAdd(structM, scanNum, sliceNumsV, relStructNum, planC);
    else
        %if number of entries is less than the preallocated space, then cut off the rest of the array.
        if lastEntry < allocatedSpace*allocations
            indicesM = indicesM(1:lastEntry,:);
            structBitsM = structBitsM(1:lastEntry);
        end
        if cellNum == 1
            planC{indexS.structureArray}(scanNum).indicesArray = indicesM;
            planC{indexS.structureArray}(scanNum).bitsArray = structBitsM;
        else
            planC{indexS.structureArrayMore}(scanNum).indicesArray{cellNum-1} = indicesM;
            planC{indexS.structureArrayMore}(scanNum).bitsArray{cellNum-1} = structBitsM;
        end
    end
end

if exist('wb')
    close(wb);
end
return


function planC = uniformAdd(mask3M, scanNum, sliceNumV, structNum, planC)
%"uniformAdd"
%   Add a single structure's slice(s) to the Uniformized Data for
%   structNum.

indexS = planC{end};

siz = getUniformScanSize(planC{indexS.scan}(scanNum));

%Find total number of structures in scannum
[assocScansV] = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
totalStructsInScan = length(find(assocScansV == scanNum));

if structNum <= 52
    cellNum = 1;
    indicesM = planC{indexS.structureArray}(scanNum).indicesArray;
    bitsM    = planC{indexS.structureArray}(scanNum).bitsArray;    
else
    cellNum = ceil((structNum-52)/8)+1;
    indicesM = planC{indexS.structureArrayMore}(scanNum).indicesArray{cellNum-1};
    bitsM    = planC{indexS.structureArrayMore}(scanNum).bitsArray{cellNum-1};
end

%Get indices on this slice.

if MLVersion < 6.5
    %ismember cannot handle uint16s in ML6.1.
    ind = find(ismember(double(indicesM(:,3)), sliceNumV));
else
    ind = find(ismember(indicesM(:,3), sliceNumV));
end

[r,c,s] = find3d(mask3M);
s = sliceNumV(s);
r = r(:)';
c = c(:)';
s = s(:)';
myDataPoints = [r',c',s'];

%Convert from rcs to index, makes intersect and setdiff faster.
%Do this manually since sub2ind has major overhead.
multiM = cumprod(siz);
mDP = double(r) + (double(c)-1)*multiM(1) + (double(s)-1)*multiM(2);
iM  = double(indicesM(ind,1)) + (double(indicesM(ind,2))-1)*multiM(1) + (double(indicesM(ind,3))-1)*multiM(2);

%Find voxels in both sets.
[c, ia, ib] = intersect(mDP, iM);

[c, i] = setdiff(mDP, c);
newValueIndicies = i;
numNewIndicies = length(i);

%Add these new points.
indicesM = [indicesM;myDataPoints(newValueIndicies, :)];

%Find points not already in Uniformized data.
if cellNum == 1

    if totalStructsInScan > 32
        bitsM = double(bitsM);
        a = double(0);        
    elseif totalStructsInScan > 16
        bitsM = uint32(bitsM);
        a = uint32(0);        
    elseif totalStructsInScan > 8
        bitsM = uint16(bitsM);        
        a = uint16(0);        
    else        
        bitsM = uint8(bitsM);
        a = uint8(0);        
    end
    bitsM(ind) = bitset(bitsM(ind), structNum, 0);
    bitsM(ind(ib)) = bitset(bitsM(ind(ib)), structNum, 1);
    %set the bits of the new points--since they are new only this struct must
    %be flipped.
    a = bitset(a, structNum, 1);
    bitsM(length(bitsM)+1:length(indicesM)) = a;
else
    bitsM(ind) = bitset(bitsM(ind), structNum - 52 - 8*(cellNum-2), 0);
    bitsM(ind(ib)) = bitset(bitsM(ind(ib)), structNum - 52 - 8*(cellNum-2), 1);
    a = uint8(0);
    %set the bits of the new points--since they are new only this struct must
    %be flipped.
    a = bitset(a, structNum - 52 - 8*(cellNum-2), 1);
    bitsM(length(bitsM)+1:length(indicesM)) = a;
end

if structNum <= 52
    planC{indexS.structureArray}(scanNum).indicesArray = indicesM;
    planC{indexS.structureArray}(scanNum).bitsArray = bitsM;
else
    planC{indexS.structureArrayMore}(scanNum).indicesArray{cellNum-1} = indicesM;
    planC{indexS.structureArrayMore}(scanNum).bitsArray{cellNum-1} = bitsM;
end
