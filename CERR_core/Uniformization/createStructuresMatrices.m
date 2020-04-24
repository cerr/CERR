%function [indicesM, structBitsM] = createStructuresMatrices(planC, scanNum, tMin, tMax, optS, hBar)
%function [indicesC, structBitsC] = createStructuresMatrices(planC, scanNum, tMin, tMax, optS, hBar)
function [indicesUpto52M, structBitsUpto52M, indicesC, structBitsC] = createStructuresMatrices(planC, scanNum, tMin, tMax, optS, hBar)
%
%"createStructuresMatrices"
%   Creates uniform structure data.
%
%   indicesM is a uint8 index Nx3 matrix, with (i,j,k) indices stored for
%   each place in the CT scan where there is some structure.
%   structBitsM is  a uint32 Nx1 matrix with a bit-wise representation
%   (32-bit numbers) of which structures are at that point.
%   If structure #1 is present at that point, then there will be a '1' in
%   the first bit.  If that structure is not present at that point, there
%   will be a '0' in the first bit.  These matrices are registered on a
%   voxel-by-voxel basis to the uniform CT scan.  Typically these are stored
%   in 'planC{indexS.structureArray}.indicesArray' or '.bitsArray'.
%
% 23 Aug 02, V H Clark
%
% Latest modifications:  15 Sep 02, JOD
%                        27 Jan 03, JOD, changes to exclude defined structures from uniformization.
%                         9 Apr 03, JOD, add waitbar handle to input args.
%                         1 Jan 04, JRA, can now use uint32 or double for structArray
%                        18 Feb 05, JRA, Support for multiple scanSets.
%                        27 Oct 05, DK, Now Compatible with Matlab 7
%
%Usage:
%   function [indicesM, structBitsM] = createStructuresMatrices(planC, tMin, tMax, optS, hBar)
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


global stateS
indexS = planC{end};


MATLABVer = version;
if MATLABVer(1) ~= '6'
    planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1 = double(planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1);
    planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2 = double(planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2);
    sizeArray               = double(getUniformScanSize(planC{indexS.scan}(scanNum)));
else
    sizeArray               = getUniformScanSize(planC{indexS.scan}(scanNum));
end
scanInfo                = planC{indexS.scan}(scanNum).scanInfo;
uniformScanInfo         = planC{indexS.scan}(scanNum).uniformScanInfo;
sliceNumSup             = uniformScanInfo.sliceNumSup;
sliceNumInf             = uniformScanInfo.sliceNumInf;
sliceNumLast            = sliceNumInf + length(getScanArrayInferior(planC{indexS.scan}(scanNum))) - 1;
uniformSliceNumTotal    = sizeArray(3);
uniformFirstZValue      = uniformScanInfo.firstZValue;
uniformSliceThickness   = uniformScanInfo.sliceThickness;
uniformLastZValue       = uniformFirstZValue + (uniformSliceNumTotal-1)*uniformSliceThickness;
CTOriginalZValues       = [scanInfo(:).zValue];
CTSliceThickness        = [planC{indexS.scan}(scanNum).scanInfo.sliceThickness];
[xV, yV, zV]            = getScanXYZVals(planC{indexS.scan}(scanNum));
CTdeltaX                = abs(xV(2) - xV(1));
CTdeltaY                = abs(yV(2) - yV(1));

CTImageSize   = [double(planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1)  double(planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2) length(planC{indexS.scan}(scanNum).scanInfo)];


%% ------------------- Matrix-based storage for structures less than or equal to 52
allocatedSpace = 1000000;  %Length of initial indicesUpto52M & structBitsUpto52M.  This predetermined size allows for only a few, if any, preallocations total.
allocations = 1; %keeps track of how many times the space has been allocated
indicesUpto52M    = zeros(allocatedSpace,3,'uint16');

[structScans, relStructNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
structInScan = find(structScans == scanNum);
structToUniformize = structInScan;
numberOfStructures = length(structInScan);

%Make structureArray, datatype based on options and defaulting to uint32.
if numberOfStructures <= 8
    structBitsUpto52M = uint8(zeros(allocatedSpace,1));
elseif numberOfStructures <= 16
    structBitsUpto52M = uint16(zeros(allocatedSpace,1));
elseif numberOfStructures <= 32
    structBitsUpto52M = uint32(zeros(allocatedSpace,1));
elseif numberOfStructures <= 52
    structBitsUpto52M = double(zeros(allocatedSpace,1));
else
    structBitsUpto52M = double(zeros(allocatedSpace,1));
    structToUniformize = structInScan(1:52);
    %error('Too many structures to uniformize: current limit is 52.');
    %cell array storage required    
end

entry = 1; %indicesUpto52M and structBitsUpto52M index counter
lastEntry = 0;

tDelta = (tMax - tMin)*.95; %saving the last 5% of time (rough estimate) for the work after the scan interpolations.
if numberOfStructures >=52
    tDelta = (tMax - tMin)*.95*52/numberOfStructures;
end
tMaxPrev = tMin;

reusableZerosM = repmat(0,[CTImageSize(1), CTImageSize(2)]);

try
    waitbar(tMin,hBar);
end

k = 0;
%for each z-slice in the uniform matrix
zSliceUniformValuesA = uniformFirstZValue : uniformSliceThickness : uniformLastZValue;
numOfUniformZSlices = length(zSliceUniformValuesA);
for zSliceUniformValue = zSliceUniformValuesA
  k = k+1;
  beginningEntry = entry;

  tMinCurr = tMaxPrev;
  tMaxCurr = tMin + (k/numOfUniformZSlices)*tDelta;
  tMaxPrev = tMaxCurr;

  %for each structure, fill in the appropriate bits using a technique similar to mask in sliceCallBack.
  for structNum = structToUniformize

    %Position of this structure relative to all structures with same
    %associated scan.
    relativeStructNum = relStructNumV(structNum);
      
    structName = planC{indexS.structures}(structNum).structureName;

    if length(scanInfo) > 1 && ~any(cmp(lower(optS.uniformizeExcludeStructs),'==',lower(structName)))

      %Pull out raster segments for requested structure.

      [allSegmentsM, planC, isError] = getRasterSegments(structNum, planC);   % APA: gives rastersegments for all CT slices
    
      if ~isempty(allSegmentsM)
        structM = findStructureMatrixForOneZSlice(allSegmentsM, zSliceUniformValue, CTOriginalZValues, CTSliceThickness, CTdeltaX, CTdeltaY, reusableZerosM);

        switch class(structBitsUpto52M)
            case 'double'
                structBit = bitset(double(0), relativeStructNum);                
            case 'uint32'
                structBit = bitset(uint32(0), relativeStructNum);
            case 'uint16'
                structBit = bitset(uint16(0), relativeStructNum);
            case 'uint8'
                structBit = bitset(uint8(0), relativeStructNum);
        end

        %now create the sparse matrix array entries
        [i,j] = find(structM);
        if ~isempty(i) %also j
            lastEntry = entry + length(i) - 1;
            if lastEntry > allocatedSpace*allocations
                indicesUpto52M = [indicesUpto52M; zeros(allocatedSpace,3,'uint16')];
                switch class(structBitsUpto52M)
                    case 'double'
                        structBitsUpto52M = [structBitsUpto52M; double(zeros(allocatedSpace,1))];
                    case 'uint32'
                        structBitsUpto52M = [structBitsUpto52M; uint32(zeros(allocatedSpace,1))];
                    case 'uint16'
                        structBitsUpto52M = [structBitsUpto52M; uint16(zeros(allocatedSpace,1))];
                    case 'uint8'
                        structBitsUpto52M = [structBitsUpto52M; uint8(zeros(allocatedSpace,1))];                    
                end
                
                allocations = allocations + 1;
            end
          indicesUpto52M(entry:lastEntry, 1) = uint16(i);
          indicesUpto52M(entry:lastEntry, 2) = uint16(j);
          indicesUpto52M(entry:lastEntry, 3) = uint16(k); %could do this all at once at the end of each slice
          structBitsUpto52M(entry:lastEntry) = structBit;
          entry = lastEntry + 1;
        end


      end

    end

  end %for each structure

  endEntry = lastEntry;

  %do unique in here
  indicesToCondenseM = double(indicesUpto52M(beginningEntry:endEntry,:));

  [uniqueindicesUpto52M, m, n] = unique(indicesToCondenseM,'rows');
  %clear m
  if size(uniqueindicesUpto52M,1) ~= size(indicesToCondenseM,1) %at least one point on one structure overlaps another structure
      
      switch class(structBitsUpto52M)
          case 'double'
              uniquestructBitsUpto52M = zeros(size(uniqueindicesUpto52M,1),1,'double');
          case 'uint32'
              uniquestructBitsUpto52M = zeros(size(uniqueindicesUpto52M,1),1,'uint32');
          case 'uint16'
              uniquestructBitsUpto52M = zeros(size(uniqueindicesUpto52M,1),1,'uint16');
          case 'uint8'
              uniquestructBitsUpto52M = zeros(size(uniqueindicesUpto52M,1),1,'uint8');
      end      
      
      for i = 1:length(n) %also the size of indicesToCondenseM in dim 1
         uniquestructBitsUpto52M(n(i)) = bitor(uniquestructBitsUpto52M(n(i)), structBitsUpto52M(i+beginningEntry-1));
      end
      
%       uniquestructBitsUpto52M = accumarray(n,...
%           structBitsUpto52M(beginningEntry:beginningEntry+length(n)-1),...
%           [length(m),1],@bitorForVec);
      
      newEndEntry = beginningEntry + length(m) - 1;
      indicesUpto52M(beginningEntry:newEndEntry,:) = uint16(uniqueindicesUpto52M);
      structBitsUpto52M(beginningEntry:newEndEntry) = uniquestructBitsUpto52M;
      lastEntry = newEndEntry;
      entry = lastEntry+1; % note that there will be non-zero entries in the matrix after the entry index which are now irrelevant and will be written over or deleted later.
  end
  
  try
      waitbar(tMaxCurr,hBar);
  end
end %for each z slice

%if number of entries is less than the preallocated space, then cut off the rest of the array.
if lastEntry < allocatedSpace*allocations
    indicesUpto52M = indicesUpto52M(1:lastEntry,:);
    structBitsUpto52M = structBitsUpto52M(1:lastEntry);
end


%% ------------------- CERR-ARRAY based storage for structures beyond 52

indicesC      = [];
structBitsC   = [];

if numberOfStructures <= 52
    return;
end

allocatedSpace = 1000000;  %Length of initial indicesM & structBitsM.  This predetermined size allows for only a few, if any, preallocations total.
allocations = 1; %keeps track of how many times the space has been allocated
indicesM    = uint16(zeros(allocatedSpace,3));
structInScan = find(structScans == scanNum);
structInScan = structInScan(53:end);
structBitsM = uint8(zeros(allocatedSpace,1)); %uint8
cellLength = ceil(length(structInScan)/8);
for cellNum=1:cellLength
    indicesC{cellNum}      = indicesM;
    structBitsC{cellNum}   = structBitsM;
end

tDelta = (tMax - tMin)*.95; %saving the last 5% of time (rough estimate) for the work after the scan interpolations.
if structInScan >=52
    tDelta = (tMax - tMin)*.95*(structInScan-52)/structInScan;
end
tMaxPrev = tMin;

reusableZerosM = repmat(0,[CTImageSize(1), CTImageSize(2)]);

try
    waitbar(tMin,hBar);
end

for cellNum = 1:cellLength
    structC{cellNum} = structInScan((cellNum-1)*8+1:min(length(structInScan),cellNum*8));
end

for cellNum = 1:cellLength
    
    entry = 1; %indicesM and structBitsM index counter
    lastEntry = 0;    
    
    structBitsM = structBitsC{cellNum};
    indicesM = indicesC{cellNum};

    k = 0;
    %for each z-slice in the uniform matrix
    zSliceUniformValuesA = uniformFirstZValue : uniformSliceThickness : uniformLastZValue;
    numOfUniformZSlices = length(zSliceUniformValuesA);
    for zSliceUniformValue = zSliceUniformValuesA
        k = k+1;
        beginningEntry = entry;

        tMinCurr = tMaxPrev;
        tMaxCurr = tMin + (k/numOfUniformZSlices)*(cellNum/cellLength)*tDelta;
        tMaxPrev = tMaxCurr;

        %for each structure, fill in the appropriate bits using a technique similar to mask in sliceCallBack.
        for structNum = structC{cellNum} %find(structScans == scanNum)

            %Position of this structure relative to all structures with same
            %associated scan.
            relativeStructNum = relStructNumV(structNum);
            
            structName = planC{indexS.structures}(structNum).structureName;

            if length(scanInfo) > 1 && ~(any(cmp(optS.uniformizeExcludeStructs,'==',upper(structName))) | any(cmp(optS.uniformizeExcludeStructs,'==',lower(structName))))

                %Pull out raster segments for requested structure.

                [allSegmentsM, planC, isError] = getRasterSegments(structNum, planC);   % APA: gives rastersegments for all CT slices

                if ~isempty(allSegmentsM)
                    structM = findStructureMatrixForOneZSlice(allSegmentsM, zSliceUniformValue, CTOriginalZValues, CTSliceThickness, CTdeltaX, CTdeltaY, reusableZerosM);

                    structBit = bitset(uint8(0), relativeStructNum - 52 - 8*(cellNum-1)); %uint8

                    %now create the sparse matrix array entries
                    [i,j] = find(structM);
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
                        indicesM(entry:lastEntry, 3) = uint16(k); %could do this all at once at the end of each slice
                        structBitsM(entry:lastEntry) = structBit;
                        entry = lastEntry + 1;
                    end

                end

            end

        end %for each structure

        endEntry = lastEntry;

        %do unique in here
        indicesToCondenseM = double(indicesM(beginningEntry:endEntry,:));

        [uniqueIndicesM, m, n] = unique(indicesToCondenseM,'rows');
        clear m
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

        try
            waitbar(tMaxCurr,hBar);
        end
    end %for each z slice

    %if number of entries is less than the preallocated space, then cut off the rest of the array.
    if lastEntry < allocatedSpace*allocations
        indicesM = indicesM(1:lastEntry,:);
        structBitsM = structBitsM(1:lastEntry);
    end

    indicesC{cellNum}      = indicesM;
    structBitsC{cellNum}   = structBitsM;

end

return
