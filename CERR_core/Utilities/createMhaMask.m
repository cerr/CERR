function success = createMhaMask(scanNum, maskFileName, planC, mask3M, threshold_bone)

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

success = 1;

try
    if exist(maskFileName,'file')
        delete(maskFileName);
    end
    
    if ~isempty(threshold_bone)
        
        % Write .mha for scanNum
        [uniformCT, uniformScanInfoS] = getUniformizedCTScan(0,scanNum,planC);
        uniformCT = permute(uniformCT, [2 1 3]);
        uniformCT = flipdim(uniformCT,3);
        
        % Change data type to int16 to allow (-)ve values
        uniformCT = int16(uniformCT) - int16(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset);
        
        uniformCTMask3M = uniformCT >= threshold_bone;
        
    else
        
        [~, uniformScanInfoS] = getUniformizedCTScan(0,scanNum,planC);
        
    end
    
    if ~isempty(mask3M)
        mask3M = permute(mask3M, [2 1 3]);
        mask3M = flipdim(mask3M,3);
    end
    
    if ~isempty(mask3M) && ~isempty(threshold_bone)
        mask3M = mask3M | uniformCTMask3M;
    elseif isempty(mask3M) && ~isempty(threshold_bone)
        mask3M = uniformCTMask3M;
    end
    
    % [dx, dy, dz]
    resolution = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness] * 10;
    
    [xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
    
    offset = [xVals(1) -yVals(1) -zVals(end)] * 10;
    
    % Write .mha file for scanNum1
    writemetaimagefile(maskFileName, mask3M, resolution, offset)
    
catch
    
    success = 0;
    
end
