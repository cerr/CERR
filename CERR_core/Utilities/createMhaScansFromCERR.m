function success = createMhaScansFromCERR(scanNum, scanFileName, planC)
% function success = createMhaScansFromCERR(scanNum, scanFileName, planC)
%
% This function creates .Mha files form CERR scan object and returns
% success (=1) if the .mha gets successfully created. This file can then
% be used an input to Plastimatch for deformable image registration.
%
% APA, 06/21/2012

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

success = 1;

try
    if exist(scanFileName,'file')
        delete(scanFileName);
    end
    % Write .mha for scanNum1
    [uniformCT, uniformScanInfoS] = getUniformizedCTScan(0,scanNum,planC);
    uniformCT = permute(uniformCT, [2 1 3]);
    uniformCT = flipdim(uniformCT,3);
    
    % Change data type to int16 to allow (-)ve values
    if ~strcmpi(class(uniformCT),'single')
        uniformCT = int16(uniformCT) - int16(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset);
    else
        uniformCT = uniformCT - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    end
    
    % [dx, dy, dz]
    resolution = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness] * 10;
    
    [xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
    
    offset = [xVals(1) -yVals(1) -zVals(end)] * 10;
    
    % Write .mha file for scanNum1
    writemetaimagefile(scanFileName, uniformCT, resolution, offset)    
    
catch    
    
    success = 0;
    
end
