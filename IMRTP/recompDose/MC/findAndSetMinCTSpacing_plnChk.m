function planC = findAndSetMinCTSpacing(planC, minSpacing, maxSpacing, alternateSpacing)
%"findAndSetMinCTSpacing"
%   Finds the minimum spacing in a CT scan and records the superior and inferior slice numbers.
%   minSpacing should be the same as optS.smallestUniformCTSliceSpacing.
%
%VHC 23 Aug 02
%
%Latest modifications:
% 25 Sept 02, JOD.
% 19 Feb 03, JOD, Change the specification of smallest CT such that a range is given:
%                 optS.lowerLimitUniformCTSliceSpacing to optS.upperLimitUniformCTSliceSpacing.
%                 Given a set of CT values, we choose the largest block which CT slice spacing which
%                 falls within these limits.  Otherwise we create a set with a spacing equal to
%                 optS.alternateUniformCTSliceSpacing.  Rewritten using blockS structure.
% 29 Apr 03, JOD, If slice thicknesses are not available, they are assigned by using the zValues.
%  8 May 03, JOD, only deduce slice thicknesses if thicknesses are not already present.
%  9 May O3, JOD, corrected faulty indexing in determining slice block to keep.
% 20 May 03, ES,  changed < to <= in block recognition loop.
% 20 May 03, JOD, corrected bug in assigning slice thicknesses to blocks of slices.
%
%Usage:
%   function planC = findAndSetMinCTSpacing(planC, minSpacing, maxSpacing, alternateSpacing)

accuracy = 1000*eps; %this value seems to work best for CT scans.  This is how much different the slice spacing
                     %can be and still be considered as approximately the same slice spacing.

%get scan info
indexS = planC{end};

for scanNum = 1:length(planC{indexS.scan})

	thicknessV = [planC{indexS.scan}(scanNum).scanInfo(:).sliceThickness];
	
	zValues = [planC{indexS.scan}(scanNum).scanInfo(:).zValue];
	
	if isempty(thicknessV) %don't know slice thicknesses for sure.
	
      CERRStatusString(['Using zValues to compute voxel thicknesses.'])
      thicknessV = deduceSliceWidths(planC);
      for i = 1 : length(thicknessV)  %put back into planC
        planC{indexS.scan}(scanNum).scanInfo(i).sliceThickness = thicknessV(i);
      end
	
	end
	
	
	%Get all blocks of the CT scan which have constant slice spacing
	%and store their characteristics.
	slice = 1;
	blockNum = 1;
	while slice <= length(thicknessV) - 1
	
        start = slice;
        finish  = slice;
	
        same = 1;
	
      go = 0;
      while same & (slice <= length(thicknessV) - 1)      %changed < to <=, ES.
        go = 1;
        if (abs(thicknessV(slice + 1) - thicknessV(slice)) < accuracy)
          slice = slice + 1;
          finish = slice;
        else
          slice = slice + 1;
          same = 0;
        end
      end
	
      %store block information
      blockS(blockNum).start = start;
      blockS(blockNum).finish = finish;
      blockS(blockNum).width = finish - start + 1;
      blockS(blockNum).spacing = thicknessV(start);
      blockNum = blockNum + 1;
      if go == 0
        slice = slice + 1;
      end
	
	end
	
	numSlices = length(thicknessV);
	
	%Choose which blocks have thicknesses fulfilling the criteria:
	
	okV = [];
	for i = 1 : length(blockS)
      if blockS(i).spacing <= maxSpacing &  blockS(i).spacing >= minSpacing
        okV = [okV, i];
      end
	end
	
	if ~isempty(okV)
      %Of those, which has the largest number of consecutive slices?
      widthV = [blockS(okV).width];
	
      indV = find(max(widthV) == widthV);
      ind = indV(1);
	
      ind2 = okV(ind);
	
      sliceThickness = blockS(ind2).spacing;
      sliceNumSup = blockS(ind2).start;
      sliceNumInf = blockS(ind2).finish;
	
	else
	
      sliceThickness = alternateSpacing;
      sliceNumMiddle = floor(numSlices/2);
      sliceNumSup = sliceNumMiddle;
      sliceNumInf = sliceNumMiddle;
	
	end
	
	uniformScanInfo = planC{indexS.scan}(scanNum).scanInfo(1);
	uniformScanInfo.sliceNumSup = sliceNumSup;
	uniformScanInfo.sliceNumInf = sliceNumInf;
	uniformScanInfo.sliceThickness = sliceThickness;
	uniformScanInfo.supInfScansCreated = 0; %scans not created yet, but the field is initialized
	uniformScanInfo.minCTValue = double(min(planC{indexS.scan}(scanNum).scanArray(:)));
	uniformScanInfo.maxCTValue = double(max(planC{indexS.scan}(scanNum).scanArray(:)));
	
	optS = planC{indexS.CERROptions};
	
	if ~isfield(optS, 'uniformizedDataType')
        optS.uniformizedDataType = 'uint8'
        planC{indexS.CERROptions} = optS;
	end
        
	
	switch optS.uniformizedDataType
	
      case 'uint8'
	
        uniformScanInfo.bytesPerPixel = 1;
	
      case 'uint16'
	
        uniformScanInfo.bytesPerPixel = 2;
	
      otherwise
	
        error('Error determining CT uniformized data type.')
	
	end
	
	%Remove unneeded holdover fields copied from scanInfo(1).
	if isfield(uniformScanInfo, 'imageNumber')
        uniformScanInfo = rmfield(uniformScanInfo, 'imageNumber');
	end
	if isfield(uniformScanInfo, 'zValue')
        uniformScanInfo = rmfield(uniformScanInfo, 'zValue');
	end
	if isfield(uniformScanInfo, 'voxelThickness')
        uniformScanInfo = rmfield(uniformScanInfo, 'voxelThickness');
	end
	
	planC{indexS.scan}(scanNum).uniformScanInfo = uniformScanInfo;
    
end