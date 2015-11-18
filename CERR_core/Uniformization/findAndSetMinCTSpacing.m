function planC = findAndSetMinCTSpacing(planC, minSpacing, maxSpacing, alternateSpacing, scanNumV)
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

accuracy = 0.001; %this value seems to work best for CT scans.  This is how much different the slice spacing
                     %can be and still be considered as approximately the same slice spacing.

%get scan info
indexS = planC{end};

% Get scan indices
if ~exist('scanNumV','var')
    scanNumV = 1:length(planC{indexS.scan});
end

for scanNum = scanNumV
    
	thicknessV = deduceSliceWidths(planC,scanNum);
	CERRStatusString('Using zValues to compute voxel thicknesses.')
      
    for i = 1 : length(thicknessV)  %put back into planC
        planC{indexS.scan}(scanNum).scanInfo(i).sliceThickness = thicknessV(i);
    end	

	%Get all blocks of the CT scan which have constant slice spacing
	%and store their characteristics.
	slice = 1;
	blockNum = 1;
    blockS = struct('');    
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
    scanArray = getScanArray(planC{indexS.scan}(scanNum));
	uniformScanInfo.minCTValue = double(min(scanArray(:)));
	uniformScanInfo.maxCTValue = double(max(scanArray(:)));
	
	optS = planC{indexS.CERROptions};
	
    if ~isfield(optS, 'uniformizedDataType')
        try
            if planC{indexS.scan}(scanNum).uniformScanInfo.bytesPerPixel == 1
                optS.uniformizedDataType = 'uint8';
            else
                optS.uniformizedDataType = 'uint16';
            end
        catch
            optFromFile = CERROptions;
            optS.uniformizedDataType = optFromFile.uniformizedDataType;
        end
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