function importIBSIPhase2DataToCERR(niiDataDir)
% importIBSIPhase2DataToCERR.m
% Download datasets from: https://github.com/theibsi/data_sets/
%-------------------------------------------------------------------------
% AI 10/06/2020
% AI 11/18/2022 Extnded for phase 2

%% Phase-1 : Synthetic phantoms
cerrPath = getCERRPath;
idxV = strfind(getCERRPath,filesep);
savePath = fullfile(cerrPath(1:idxV(end-1)),...
    'Unit_Testing\data_for_cerr_tests\IBSI2_synthetic_phantoms');

subDir = 'ibsi_2_digital_phantom';
synthDataDir = fullfile(niiDataDir,subDir,'nifti');
dirS = dir(synthDataDir);
dirS(1:2) = [];
for nDataset = 1:length(dirS)
    
    %Import scan
    synthDatasetName = fullfile(synthDataDir,dirS(nDataset).name,'image');
    synthDatasetDirS = dir([synthDatasetName,filesep,'*.nii.gz']);
    fileName = synthDatasetDirS.name;
    scanName = strtok(fileName,'.');
    filePath = fullfile(synthDatasetName,synthDatasetDirS.name);

    planC = nii2cerr(filePath,scanName,[],0);
    planC = updatePlanFields(planC);
    planC = quality_assure_planC(fileName,planC);
    
    %Create 'wholeScan' structure
    addMask3M = true(size(getScanArray(1,planC)));
    planC = maskToCERRStructure(addMask3M,0,1,...
            'wholeScan',planC);
    
    save_planC(planC,[],'PASSED',fullfile(savePath,...
        [scanName,'.mat']));
    
end

%% Phase-2 CT phantom
subDir = 'ibsi_2_ct_radiomics_phantom';
savePath = fullfile(cerrPath(1:idxV(end-1)),...
    'Unit_Testing\data_for_cerr_tests\IBSI2_CT_phantom');
scanName = subDir;
ctScanFile = fullfile(niiDataDir,subDir,'nifti','image','phantom.nii.gz');
ctMaskFile = fullfile(niiDataDir,subDir,'nifti','mask','mask.nii.gz');

planC = nii2cerr(ctScanFile,scanName,[],0);
planC = updatePlanFields(planC);
planC = quality_assure_planC(ctScanFile,planC);

%Create 'wholeScan' structure
mask3M = niftiread(ctMaskFile);
mask3M = flip(permute(mask3M,[2 1 3]),3);
planC = maskToCERRStructure(mask3M,0,1,...
    'ROI',planC);

planD = nii2cerr(ctMaskFile,'mask',[],0);
planD = updatePlanFields(planD);
planD = quality_assure_planC(ctMaskFile,planD);



save_planC(planC,[],'PASSED',fullfile(savePath,...
        [scanName,'.mat']));
end