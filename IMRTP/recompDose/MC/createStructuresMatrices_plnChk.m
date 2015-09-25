function [indicesM, structBitsM] = createStructuresMatrices(planC, scanNum, tMin, tMax, optS, hBar)
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

scanInfo                = planC{indexS.scan}(scanNum).scanInfo;
uniformScanInfo         = planC{indexS.scan}(scanNum).uniformScanInfo;
sliceNumSup             = uniformScanInfo.sliceNumSup;
sliceNumInf             = uniformScanInfo.sliceNumInf;
sliceNumLast            = sliceNumInf + length(planC{indexS.scan}(scanNum).scanArrayInferior) - 1;
sizeArray               = getUniformScanSize(planC{indexS.scan}(scanNum));
uniformSliceNumTotal    = sizeArray(3);
uniformFirstZValue      = uniformScanInfo.firstZValue;
uniformSliceThickness   = uniformScanInfo.sliceThickness;
uniformLastZValue       = uniformFirstZValue + (uniformSliceNumTotal-1)*uniformSliceThickness;
CTOriginalZValues       = [scanInfo(:).zValue];
CTSliceThickness        = [planC{indexS.scan}(scanNum).scanInfo.sliceThickness];
[xV, yV, zV]            = getScanXYZVals(planC{indexS.scan}(scanNum));
CTdeltaX                = abs(xV(2) - xV(1));
CTdeltaY                = abs(yV(2) - yV(1));
    
CTImageSize   = [planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1  planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2 length(planC{indexS.scan}(scanNum).scanInfo)];

allocatedSpace = 1000000;  %Length of initial indicesM & structBitsM.  This predetermined size allows for only a few, if any, preallocations total.
allocations = 1; %keeps track of how many times the space has been allocated
indicesM    = uint16(zeros(allocatedSpace,3));

[structScans, relStructNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
numberOfStructures = length(find(structScans == scanNum));

%Make structureArray, datatype based on options and defaulting to uint32.
if numberOfStructures <= 8
    structBitsM = uint8(zeros(allocatedSpace,1));
elseif numberOfStructures <= 16
    structBitsM = uint16(zeros(allocatedSpace,1));
elseif numberOfStructures <= 32
    structBitsM = uint32(zeros(allocatedSpace,1));
elseif numberOfStructures <= 52
    structBitsM = double(zeros(allocatedSpace,1));
else
    error('Too many structures to uniformize: current limit is 52.');
end

entry = 1; %indicesM and structBitsM index counter
lastEntry = 0;

tDelta = (tMax - tMin)*.95; %saving the last 5% of time (rough estimate) for the work after the scan interpolations.
tMaxPrev = tMin;

reusableZerosM = repmat(0,[CTImageSize(1), CTImageSize(2)]);

waitbar(tMin,hBar);

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
  for structNum = find(structScans == scanNum)

    %Position of this structure relative to all structures with same
    %associated scan.
    relativeStructNum = relStructNumV(structNum);
      
    structName = planC{indexS.structures}(structNum).structureName;

    if ~(any(cmp(optS.uniformizeExcludeStructs,'==',upper(structName))) | any(cmp(optS.uniformizeExcludeStructs,'==',lower(structName))))

      %Pull out raster segments for requested structure.
      [allSegmentsM, planC, isError] = getRasterSegments(structNum, planC);            

      if ~isempty(allSegmentsM)
        structM = findStructureMatrixForOneZSlice(allSegmentsM, zSliceUniformValue, CTOriginalZValues, CTSliceThickness, CTdeltaX, CTdeltaY, reusableZerosM);

        switch class(structBitsM)
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
  
  
  waitbar(tMaxCurr,hBar);
end %for each z slice

%if number of entries is less than the preallocated space, then cut off the rest of the array.
if lastEntry < allocatedSpace*allocations
    indicesM = indicesM(1:lastEntry,:);
    structBitsM = structBitsM(1:lastEntry);
end

return