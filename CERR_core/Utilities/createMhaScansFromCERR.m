function success = createMhaScansFromCERR(scanNum, scanFileName, planC)
% function success = createMhaScansFromCERR(scanNum, scanFileName, planC)
%
% Tis function creates .Mha files form CERR scan object and returns
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
    
    % Write .mha for scanNum1
    [uniformCT, uniformScanInfoS] = getUniformizedCTScan(0,scanNum);
    uniformCT = permute(uniformCT, [2 1 3]);
    uniformCT = flipdim(uniformCT,1);
    uniformCT = flipdim(uniformCT,3);
    
    % [dx, dy, dz]
    resolution = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness];
    
    [xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
    
    offset = [xVals(1) -yVals(1) -zVals(end)];
    
    % Write .mha file for scanNum1
    writemetaimagefile(scanFileName, uniformCT, resolution, offset)    
    
catch    
    
    success = 0;
    
end
