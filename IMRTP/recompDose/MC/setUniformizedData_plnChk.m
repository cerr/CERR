function planC = setUniformizedData(planC, optS)
%"setUniformizedData"
%   Script function to create uniformized data and store it in the
%   passed plan.  If optS is not specified, the stateS stored in the plan
%   is used.  Based on code by Vanessa H. Clark.
%
% JRA 12/29/03
%
% Usage: planC = setUniformizedData(planC, optS)

indexS = planC{end};

if ~exist('optS')
    optS = planC{indexS.CERROptions};
end

hBar = waitbar(0, 'Creation of uniformized CT scan and structures...');
planC = findAndSetMinCTSpacing(planC, optS.lowerLimitUniformCTSliceSpacing, optS.upperLimitUniformCTSliceSpacing, optS.alternateLimitUniformCTSliceSpacing);
planC = uniformizeScanSupInf(planC, 0, 1/2, optS, hBar);
for scanNum = 1:length(planC{indexS.scan})
    [indicesM, structBitsM] = createStructuresMatrices(planC, scanNum, 1/2, 1, optS, hBar);
    planC = storeStructuresMatrices(planC, indicesM, structBitsM, scanNum);
end
close(hBar);