function success = createMhaDosesFromCERR(doseNum, doseFileName, planC)
% function success = createMhaDosesFromCERR(doseNum, doseFileName, planC)
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
    
    % get doseArray
    dose3M = single(getDoseArray(doseNum, planC));
    dose3M = permute(dose3M, [2 1 3]);
    dose3M = flipdim(dose3M,3);
    
    % [dx, dy, dz]    
    [xVals, yVals, zVals] = getDoseXYZVals(planC{indexS.dose}(doseNum));

    resolution = [planC{indexS.dose}(doseNum).horizontalGridInterval, -planC{indexS.dose}(doseNum).verticalGridInterval, zVals(2)-zVals(1)] * 10;
    
    offset = [xVals(1) -yVals(1) -zVals(end)] * 10;
    
    % Write .mha file for doseNum1
    writemetaimagefile(doseFileName, dose3M, resolution, offset)    
    
catch    
    
    success = 0;
    
end
