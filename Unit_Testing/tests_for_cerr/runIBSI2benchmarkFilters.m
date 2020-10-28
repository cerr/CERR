function runIBSI2benchmarkFilters(outDir)
% Usage: runIBSI2benchmarkFilters(outDir);
% -----------------------------------------------------------------------
% Inputs
% outDir : Path to output directory.
% -----------------------------------------------------------------------
% AI 10/06/2020
% Ref: https://arxiv.org/pdf/2006.05470.pdf (Table 6.1)

%% Paths to IBSI phase-2 datasets & calc. parameters
cerrPath = getCERRPath;
idxV = strfind(getCERRPath,filesep);
dataDirName = fullfile(cerrPath(1:idxV(end-1)),...
    'Unit_Testing\data_for_cerr_tests\IBSI2_synthetic_phantoms');
configDirName = fullfile(cerrPath(1:idxV(end-1)),...
    'Unit_Testing\settings_for_comparisons');

%% Get metadata
niiDataDir = fullfile(cerrPath(1:idxV(end-1)),...
    'Unit_Testing\data_for_cerr_tests\IBSI2_synthetic_phantoms');
metadataS.checkerboard = getMetadata(niiDataDir,'checkerboard');
metadataS.impulse = getMetadata(niiDataDir,'impulse');
metadataS.sphere = getMetadata(niiDataDir,'sphere');

%% Compute response maps
%% 1.a
fileName = fullfile(dataDirName,'checkerboard.mat');
[planC,structNum] = preparePlanC(fileName);
index1S = planC{end};
%1.a.1
paramFile = fullfile(configDirName,'IBSIPhase2ID1a1.json');
planC = generateTextureMapFromPlanC(planC,structNum,paramFile);
scanNum = length(planC{index1S.scan});
planC{index1S.scan}(scanNum).scanType = ...
    [planC{index1S.scan}(scanNum).scanType,'_1a1'];
%1.a.2
paramFile = fullfile(configDirName,'IBSIPhase2ID1a2.json');
planC = generateTextureMapFromPlanC(planC,structNum,paramFile);
scanNum = length(planC{index1S.scan});
planC{index1S.scan}(scanNum).scanType = ...
    [planC{index1S.scan}(scanNum).scanType,'_1a2'];
%1.a.3
paramFile = fullfile(configDirName,'IBSIPhase2ID1a3.json');
planC = generateTextureMapFromPlanC(planC,structNum,paramFile);
scanNum = length(planC{index1S.scan});
planC{index1S.scan}(scanNum).scanType = ...
    [planC{index1S.scan}(scanNum).scanType,'_1a3'];
%1.a.4
paramFile = fullfile(configDirName,'IBSIPhase2ID1a4.json');
planC = generateTextureMapFromPlanC(planC,structNum,paramFile);
scanNum = length(planC{index1S.scan});
planC{index1S.scan}(scanNum).scanType = ...
    [planC{index1S.scan}(scanNum).scanType,'_1a4'];

planName = fullfile(outDir,'1a.mat');
save_planC(planC,[],'PASSED',planName);
exportScans(planName,outDir,'1a',metadataS.checkerboard);

clear planC
%% 2.a
fileName = fullfile(dataDirName,'impulse.mat');
[planC,structNum] = preparePlanC(fileName);
paramFile = fullfile(configDirName,'IBSIPhase2ID2a.json');

planC = generateTextureMapFromPlanC(planC,structNum,paramFile);
scanNum = length(planC{index1S.scan});
planC{index1S.scan}(scanNum).scanType = ...
    [planC{index1S.scan}(scanNum).scanType,'_2a'];

planName = fullfile(outDir,'2a.mat');
save_planC(planC,[],'PASSED',planName);
exportScans(planName,outDir,'2a',metadataS.impulse);

clear planC
%% 2.b
fileName = fullfile(dataDirName,'checkerboard.mat');
[planC,structNum] = preparePlanC(fileName);
paramFile = fullfile(configDirName,'IBSIPhase2ID2b.json');

planC = generateTextureMapFromPlanC(planC,structNum,paramFile);
scanNum = length(planC{index1S.scan});
planC{index1S.scan}(scanNum).scanType = ...
    [planC{index1S.scan}(scanNum).scanType,'_2b'];

planName = fullfile(outDir,'2b.mat');
save_planC(planC,[],'PASSED',planName);
exportScans(planName,outDir,'2b',metadataS.checkerboard);

clear planC
%% 3.a.1
fileName = fullfile(dataDirName,'impulse.mat');
[planC,structNum] = preparePlanC(fileName);
paramFile = fullfile(configDirName,'IBSIPhase2ID3a1.json');

planC = generateTextureMapFromPlanC(planC,structNum,paramFile);
scanNum = length(planC{index1S.scan});
planC{index1S.scan}(scanNum).scanType = ...
    [planC{index1S.scan}(scanNum).scanType,'_3a1'];

planName = fullfile(outDir,'3a1.mat');
save_planC(planC,[],'PASSED',planName);
exportScans(planName,outDir,'3a',metadataS.impulse);

clear planC
%% 3.b.1
fileName = fullfile(dataDirName,'checkerboard.mat');
[planC,structNum] = preparePlanC(fileName);
paramFile = fullfile(configDirName,'IBSIPhase2ID3b1.json');

planC = generateTextureMapFromPlanC(planC,structNum,paramFile);
scanNum = length(planC{index1S.scan});
planC{index1S.scan}(scanNum).scanType = ...
    [planC{index1S.scan}(scanNum).scanType,'_3b1'];

planName = fullfile(outDir,'3b1.mat');
save_planC(planC,[],'PASSED',planName);
exportScans(planName,outDir,'3b',metadataS.checkerboard);

%% 5.a.1
fileName = fullfile(dataDirName,'impulse.mat');
[planC,structNum] = preparePlanC(fileName);
paramFile = fullfile(configDirName,'IBSIPhase2ID5a1.json');

planC = generateTextureMapFromPlanC(planC,structNum,paramFile);
scanNum = length(planC{index1S.scan});
planC{index1S.scan}(scanNum).scanType = ...
    [planC{index1S.scan}(scanNum).scanType,'_5a1'];

planName = fullfile(outDir,'5a1.mat');
save_planC(planC,[],'PASSED',planName);
exportScans(planName,outDir,'5a',metadataS.impulse);

clear planC
%% 6.a.1
fileName = fullfile(dataDirName,'sphere.mat');
[planC,structNum] = preparePlanC(fileName);
paramFile = fullfile(configDirName,'IBSIPhase2ID6a1.json');

planC = generateTextureMapFromPlanC(planC,structNum,paramFile);
scanNum = length(planC{index1S.scan});
planC{index1S.scan}(scanNum).scanType = ...
    [planC{index1S.scan}(scanNum).scanType,'6a1'];

planName = fullfile(outDir,'6a1.mat');
save_planC(planC,[],'PASSED',planName);
exportScans(planName,outDir,'6a',metadataS.sphere);

%% -- Supporting functions --

    function infoS = getMetadata(niftiDataDir,phantom)
        infoS = struct();
        I = niftiinfo(fullfile(niftiDataDir,[phantom,'.nii']));
        keepFieldsC = {'ImageSize','PixelDimensions','SpaceUnits',...
            'TimeUnits','Qfactor','Version','SliceCode',...
            'FrequencyDimension','PhaseDimension','SpatialDimension'};
        for n = 1:length(keepFieldsC)
            infoS.(keepFieldsC{n}) = I.(keepFieldsC{n});
        end
        infoS.Datatype = 'double';
        infoS.Description = 'Response map';
        
    end

    function [planC,structNum] = preparePlanC(fileName)
        planC = loadPlanC(fileName,tempdir);
        planC = updatePlanFields(planC);
        planC = quality_assure_planC(fileName,planC);
        indexS = planC{end};
        strC = {planC{indexS.structures}.structureName};
        structNum = getMatchingIndex('wholeScan',strC,'EXACT');
    end

    function exportScans(planName,outDir,outFname,infoS)
        plan2C = loadPlanC(planName,tempdir);
        plan2C = updatePlanFields(plan2C);
        plan2C = quality_assure_planC(planName,plan2C);
        indexS = plan2C{end};
        nScans = length(plan2C{indexS.scan});
        for m = 2:nScans
            %Get texture map
            scan3M = double(getScanArray(m,plan2C));
            CToffset = plan2C{indexS.scan}(m).scanInfo(1).CTOffset;
            scan3M = scan3M - double(CToffset);
            %Flip dim
            scan3M = flip(permute(scan3M,[2,1,3]),3);
            %Write to .nii file
            saveName = [outFname,num2str(m-1),'.nii'];
            niftiwrite(scan3M,fullfile(outDir,saveName),infoS);
        end
    end

end
