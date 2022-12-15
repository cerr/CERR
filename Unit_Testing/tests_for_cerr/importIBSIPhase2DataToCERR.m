function importIBSIPhase2DataToCERR(dataDir)
% importIBSIPhase2DataToCERR.m
% Download datasets from: https://github.com/theibsi/data_sets/
%-------------------------------------------------------------------------
% AI 10/06/2020
% AI 11/18/2022 Extnded for phase 2
% AI 12/10/2022 Extended for phase 3

%% Phase-1 : Synthetic phantoms
cerrPath = getCERRPath;
idxV = strfind(getCERRPath,filesep);
savePath = fullfile(cerrPath(1:idxV(end-1)),...
    'Unit_Testing\data_for_cerr_tests\IBSI2_synthetic_phantoms');

subDir = 'ibsi_2_digital_phantom';
synthDataDir = fullfile(dataDir,subDir,'nifti');
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
dcmMaskDir = fullfile(dataDir,subDir,'dicom','mask');
maskDirS = dir([dcmMaskDir,filesep,'*.dcm']);
dcmMaskPath = fullfile(dcmMaskDir,maskDirS.name);
outFileName = [savePath,filesep,'ibsi_2_ct_radiomics_phantom.mat'];

dcmScanDir = fullfile(dataDir,subDir,'dicom','image');
%Copy RT struct to be 'image' dir
copyfile(dcmMaskPath,dcmScanDir);

%planC = dcmdir2planC(dcmDataDir);
planC = importDICOM(dcmScanDir,savePath,true);
movefile([savePath,filesep,'image.mat'],outFileName);
planC = loadPlanC(outFileName,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(outFileName,planC);

%Rename structure
indexS = planC{end};
planC{indexS.structures}(1).structureName = 'ROI';

save_planC(planC,[],'PASSED',outFileName);

%% IBSI2 phase 3
subDir = 'IBSI2_multimodal_data';
savePath = fullfile(cerrPath(1:idxV(end-1)),...
    'Unit_Testing\data_for_cerr_tests\IBSI2_multimodal_data');
allData = fullfile(dataDir,subDir);
modC = {'CT','MR_T1','PET'};

scanDirS = dir(allData);
scanDirS(1:2) = [];

for nDir = 1:length(scanDirS)

    scanName = scanDirS(nDir).name;
    outFileName = [savePath,filesep,scanName,'.mat'];

    for nMod = 1:length(modC)

        %Scan dir
        dcmScanDir = fullfile(dataDir,subDir,scanName,modC{nMod},'image');

        %Copy RT struct to be 'image' dir
        dcmMaskDir = fullfile(dataDir,subDir,scanName,modC{nMod},'mask');
        maskDirS = dir([dcmMaskDir,filesep,'*.dcm']);
        dcmMaskPath = fullfile(dcmMaskDir,maskDirS.name);
        copyfile(dcmMaskPath,dcmScanDir);

        
        %Import to CERR
        planD = importDICOM(dcmScanDir,savePath,true);
        movefile([savePath,filesep,'image.mat'],outFileName);
        planD = loadPlanC(outFileName,tempdir);
        planD = updatePlanFields(planD);
        planD = quality_assure_planC(outFileName,planD);
        if nMod==1
            planC = planD;
        else
            planC = planMerge(planC,planD,'all','all','all',outFileName);
        end
        
        %Rename structure
        indexS = planC{end};
        planC{indexS.structures}(end).structureName = [modC{nMod},'_ROI'];
    end

    save_planC(planC,[],'PASSED',outFileName);
    clear planC
end

end