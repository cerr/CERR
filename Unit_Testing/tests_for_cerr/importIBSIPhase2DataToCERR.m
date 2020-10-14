function importIBSIPhase2DataToCERR(niiDataDir)
% Download dataset from: https://github.com/theibsi/data_sets/tree/master/ibsi_2_digital_phantom/nifti
% niiDataDir should contain .nii image files only.
%
% AI 10/06/2020

cerrPath = getCERRPath;
idxV = strfind(getCERRPath,filesep);
savePath = fullfile(cerrPath(1:idxV(end-1)),...
    'Unit_Testing\data_for_cerr_tests\IBSI2_synthetic_phantoms');


dirS = dir([niiDataDir,filesep,'*.nii']);
for nDataset = 1:length(dirS)
    
    %Import scan
    fileName = fullfile(niiDataDir,dirS(nDataset).name);
    scanName = strtok(dirS(nDataset).name,'.');
    planC = nii2cerr(fileName,scanName,[],0);
    planC = updatePlanFields(planC);
    planC = quality_assure_planC(fileName,planC);
    
    %Create 'wholeScan' structure
    addMask3M = true(size(getScanArray(1,planC)));
    planC = maskToCERRStructure(addMask3M,0,1,...
            'wholeScan',planC);
    
    save_planC(planC,[],'PASSED',fullfile(savePath,...
        [scanName,'.mat']));
    
end