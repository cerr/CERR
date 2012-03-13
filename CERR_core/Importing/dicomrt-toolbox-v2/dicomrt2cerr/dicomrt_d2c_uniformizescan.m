function [planC] = dicomrt_d2c_uniformizescan(planC,optS,flagVOI)
% dicomrt_d2c_uniformizescan(planC,opts)
%
% Create uniformized CT dataset. Original code from  initializeCERR.
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Create uniformized datasets
str = optS.createUniformizedDataset;
if strcmp(lower(str),'yes') & strcmpi(optS.loadCT,'yes')    
    % Create uniformized 3D scan set
    hBar = waitbar(0, 'Creation of uniformized scan and structures...');
    planC = findAndSetMinCTSpacing(planC, optS.lowerLimitUniformCTSliceSpacing, ...
        optS.upperLimitUniformCTSliceSpacing, optS.alternateLimitUniformCTSliceSpacing);
    planC = uniformizeScanSupInf(planC, 0, 1/2, optS, hBar);

    % Create structure indices into the 3D dataset
    [indicesM, structBitsM, indicesC, structBitsC] = createStructuresMatrices(planC,1,1/2, 1, optS, hBar);
    planC = storeStructuresMatrices(planC, indicesM, structBitsM, indicesC, structBitsC);
    close(hBar)    
end
