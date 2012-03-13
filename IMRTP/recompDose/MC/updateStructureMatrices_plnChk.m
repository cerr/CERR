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
%   planC = updateStructureMatrices(planC, editStructNum, sliceNumsV)

	indexS = planC{end};
    
    %Figure out what relative structNum this is for the specified scanNum;
    [scanNum, relStructNum] = getStructureAssociatedScan(editStructNum, planC);
    	
	%Get background data on scan, uniformized data assoc. with structure.
	scanInfo            = planC{indexS.scan}(scanNum).scanInfo;
	sizeArray           = getUniformScanSize(planC{indexS.scan}(scanNum));
    [xV, yV, zV]        = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
    [xVs, yVs, zVs]     = getScanXYZVals(planC{indexS.scan}(scanNum));
	CTOriginalZValues   = [scanInfo(:).zValue];
	CTSliceThickness    = [scanInfo(:).sliceThickness];
	CTdeltaX            = abs(xV(2) - xV(1));
	CTdeltaY            = abs(yV(2) - yV(1));
        	
	%Retrieve the structure's raster segments.
	[allSegmentsM, planC, isError] = getRasterSegments(editStructNum, planC);    
	
    reusableZerosM = repmat(logical(0),[sizeArray(1), sizeArray(2)]);
    
    %Initialize structureArray and bits array if they dont exist.
    if length(planC{indexS.structureArray}) < scanNum;
        tmp = uint16([0 0 0]);
        tmp(1,:) = [];
        planC{indexS.structureArray}(scanNum).indicesArray = tmp;
        tmp = uint8(0);
        tmp(1) = [];
        planC{indexS.structureArray}(scanNum).bitsArray = tmp;
    end        
	
	%If we have exceeded the max for current datatype, increase it.
	switch class(planC{indexS.structureArray}(scanNum).bitsArray)
        case 'uint8'
            if relStructNum > 8
                planC{indexS.structureArray}(scanNum).bitsArray = uint16(planC{indexS.structureArray}(scanNum).bitsArray);
            end
        case 'uint16'
            if relStructNum > 16
                planC{indexS.structureArray}(scanNum).bitsArray = uint32(planC{indexS.structureArray}(scanNum).bitsArray);
            end
        case 'uint32'
            if relStructNum > 32
                planC{indexS.structureArray}(scanNum).bitsArray = double(planC{indexS.structureArray}(scanNum).bitsArray);
            end
        case 'double'
            %Can up to uint64 here if 52 is not enough in the future.
	end    
	
    %Clear old data for this structure.  If sliceNumsV is specified clear
    %only those slices, otherwise clear all slices.
    if exist('sliceNumsV')
        if MLVersion < 6.5
            %ML6.1 ismember cannot handle uint16.  Must double in this case.
            tf = ismember(double(planC{indexS.structureArray}(scanNum).indicesArray(:,3)), sliceNumsV);
        else
            tf = ismember(planC{indexS.structureArray}(scanNum).indicesArray(:,3), sliceNumsV);            
        end
        planC{indexS.structureArray}(scanNum).bitsArray(tf) = bitset(planC{indexS.structureArray}(scanNum).bitsArray(tf), relStructNum, 0);
    else
        planC{indexS.structureArray}(scanNum).bitsArray = bitset(planC{indexS.structureArray}(scanNum).bitsArray, relStructNum, 0);
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
      
      %Build the mask array, then add the mask to the uniform data.
      for zSliceUniformValue = zV(sliceNumsV)
        k = k+1;
        waitbar(k/length(sliceNumsV), wb);
        structSlc = findStructureMatrixForOneZSlice(allSegmentsM, zSliceUniformValue, CTOriginalZValues, CTSliceThickness, CTdeltaX, CTdeltaY, reusableZerosM);
        structM(:,:,k) = logical(structSlc);   
      end
      planC = uniformAdd(structM, scanNum, sliceNumsV, relStructNum, planC);  
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
	
	indicesM = planC{indexS.structureArray}(scanNum).indicesArray;
	bitsM    = planC{indexS.structureArray}(scanNum).bitsArray;
	
	%Get indices on this slice.
    
    if MLVersion < 6.5
        %ismember cannot handle uint16s in ML6.1.
    	ind = find(ismember(double(indicesM(:,3)), sliceNumV));
    else
        ind = find(ismember(indicesM(:,3), sliceNumV));
    end
	
	[r,c,s] = find3d(mask3M);
	s = sliceNumV(s);
	myDataPoints = [r',c',s'];
	
	%Convert from rcs to index, makes intersect and setdiff faster.
    %Do this manually since sub2ind has major overhead.
    multiM = cumprod(siz);
    mDP = double(r) + (double(c)-1)*multiM(1) + (double(s)-1)*multiM(2);
	iM  = double(indicesM(ind,1)) + (double(indicesM(ind,2))-1)*multiM(1) + (double(indicesM(ind,3))-1)*multiM(2);
	
	%Find voxels in both sets.
	[c, ia, ib] = intersect(mDP, iM);
	
	%Find points not already in Uniformized data.
	bitsM(ind) = bitset(bitsM(ind), structNum, 0);
	bitsM(ind(ib)) = bitset(bitsM(ind(ib)), structNum, 1);
	[c, i] = setdiff(mDP, c);
	
	newValueIndicies = i;
	numNewIndicies = length(i);  
	
	%Add these new points.
	indicesM = [indicesM;myDataPoints(newValueIndicies, :)];
	
	a = 0;
	%set the bits of the new points--since they are new only this struct must
	%be flipped.
	a = bitset(a, structNum, 1);
	bitsM(length(bitsM)+1:length(indicesM)) = a;
	
	planC{indexS.structureArray}(scanNum).indicesArray = indicesM;
	planC{indexS.structureArray}(scanNum).bitsArray = bitsM;   