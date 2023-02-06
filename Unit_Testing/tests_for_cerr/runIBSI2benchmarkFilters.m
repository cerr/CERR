function runIBSI2benchmarkFilters(outDir,config)
% Usage: runIBSI2benchmarkFilters(outDir,config);
% -----------------------------------------------------------------------
% Inputs
% outDir : Path to output directory.
% config : 
% -----------------------------------------------------------------------
% AI 10/06/2020
% Ref: https://arxiv.org/pdf/2006.05470.pdf (Table 6.1)

if ~exist('config','var')
    config = 'all';
end

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
switch(config)

    case '1a'
        fileName = fullfile(dataDirName,'checkerboard.mat');
        [planC,structNum] = preparePlanC(fileName);
        indexS = planC{end};
        %1.a.1
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID1a1.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);

        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_1a1'];
        %1.a.2
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID1a2.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_1a2'];
        %1.a.3
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID1a3.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_1a3'];
        %1.a.4
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID1a4.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_1a4'];

        planName = fullfile(outDir,'1a.mat');
        save_planC(planC,[],'PASSED',planName);
        exportScans(planName,outDir,'1a',metadataS.checkerboard);

    case '1b'
        fileName = fullfile(dataDirName,'impulse.mat');
        [planC,structNum] = preparePlanC(fileName);
        indexS = planC{end};
        %1.b.1
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID1b1.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_1b1'];

        planName = fullfile(outDir,'1b1.mat');
        save_planC(planC,[],'PASSED',planName);
        exportScans(planName,outDir,'1b',metadataS.impulse);

    case '2a'
        fileName = fullfile(dataDirName,'impulse.mat');
        [planC,structNum] = preparePlanC(fileName);
        indexS = planC{end};
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID2a.json');

        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_2a'];

        planName = fullfile(outDir,'2a.mat');
        save_planC(planC,[],'PASSED',planName);
        exportScans(planName,outDir,'2a',metadataS.impulse);

    case '2b'
        fileName = fullfile(dataDirName,'checkerboard.mat');
        [planC,structNum] = preparePlanC(fileName);
        indexS = planC{end};
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID2b.json');

        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_2b'];

        planName = fullfile(outDir,'2b.mat');
        save_planC(planC,[],'PASSED',planName);
        exportScans(planName,outDir,'2b',metadataS.checkerboard);

    case '2c'
        fileName = fullfile(dataDirName,'checkerboard.mat');
        [planC,structNum] = preparePlanC(fileName);
        indexS = planC{end};
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID2c.json');

        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_2c'];

        planName = fullfile(outDir,'2c.mat');
        save_planC(planC,[],'PASSED',planName);
        exportScans(planName,outDir,'2c',metadataS.checkerboard);

    case '3a'
        % 3.a.1
        fileName = fullfile(dataDirName,'impulse.mat');
        [planC,structNum] = preparePlanC(fileName);
        indexS = planC{end};
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID3a1.json');

        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_3a1'];

        %3.a.2
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID3a2.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        indexS = planC{end};
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_3a2'];

        % 3.a.3
        %         %Get response map from 3.a.2
        %         response3M = getScanArray(scanNum,planC);
        %         %Create mask (temp)
        %         mask3M = true(size(response3M));
        %         planC = maskToCERRStructure(mask3M,0,scanNum,'wholeScan',planC);
        %         strNum = length(planC{indexS.structures});
        %         %Run mean filter to compute energy
        %         paramFile = fullfile(configDirName,'IBSIPhase2-1ID3a3.json');
        %         planC = generateTextureMapFromPlanC(planC,strNum,paramFile);
        %         %Delete mask
        %         planC = deleteStructure(planC,strNum);
        %         %Import to CERR
        %         scanNum = length(planC{indexS.scan});
        %         planC{indexS.scan}(scanNum).scanType = ...
        %             [planC{indexS.scan}(scanNum).scanType,'_3a3'];

        paramFile = fullfile(configDirName,'IBSIPhase2-1ID3a3.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        indexS = planC{end};
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_3a3'];

        planName = fullfile(outDir,'3a.mat');
        save_planC(planC,[],'PASSED',planName);
        exportScans(planName,outDir,'3a',metadataS.impulse);

    case '3b'
        % 3.b.1
        fileName = fullfile(dataDirName,'checkerboard.mat');
        [planC,structNum] = preparePlanC(fileName);
        indexS = planC{end};
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID3b1.json');

        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_3b1'];

        % 3.b.2
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID3b2.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_3b2'];

        % 3.b.3
        %         %Get response map from 3.b.2
        %         response3M = getScanArray(scanNum,planC);
        %
        %         %Create mask (temp)
        %         mask3M = true(size(response3M));
        %         planC = maskToCERRStructure(mask3M,0,scanNum,'wholeScan',planC);
        %         strNum = length(planC{indexS.structures});
        %
        %         %Run mean filter to compute energy
        %         paramFile = fullfile(configDirName,'IBSIPhase2-1ID3b3.json');
        %         planC = generateTextureMapFromPlanC(planC,strNum,paramFile);
        %
        %         %Delete mask
        %         planC = deleteStructure(planC,strNum);
        %
        %         %Import to CERR
        %         scanNum = length(planC{indexS.scan});
        %         planC{indexS.scan}(scanNum).scanType = ...
        %             [planC{indexS.scan}(scanNum).scanType,'_3b3'];
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID3b3.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_3b3'];

        planName = fullfile(outDir,'3b.mat');
        save_planC(planC,[],'PASSED',planName);
        exportScans(planName,outDir,'3b',metadataS.impulse);

    case '3c'
        % 3.c.1
        fileName = fullfile(dataDirName,'checkerboard.mat');
        [planC,structNum] = preparePlanC(fileName);
        indexS = planC{end};
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID3c1.json');

        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_3c1'];

        % 3.c.2
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID3c2.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_3c2'];

        %3.c.3
        %         %Get response map from 3.c.2
        %         response3M = getScanArray(scanNum,planC);
        %
        %         %Create mask (temp)
        %         mask3M = true(size(response3M));
        %         planC = maskToCERRStructure(mask3M,0,scanNum,'wholeScan',planC);
        %         strNum = length(planC{indexS.structures});
        %
        %         %Run mean filter to compute energy
        %         paramFile = fullfile(configDirName,'IBSIPhase2-1ID3c3.json');
        %         planC = generateTextureMapFromPlanC(planC,strNum,paramFile);
        %
        %         %Delete mask
        %         planC = deleteStructure(planC,strNum);
        %
        %         %Import to CERR
        %         scanNum = length(planC{indexS.scan});
        %         planC{indexS.scan}(scanNum).scanType = ...
        %             [planC{indexS.scan}(scanNum).scanType,'_3c3'];

        paramFile = fullfile(configDirName,'IBSIPhase2-1ID3c3.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_3c3'];

        planName = fullfile(outDir,'3c.mat');
        save_planC(planC,[],'PASSED',planName);
        exportScans(planName,outDir,'3c',metadataS.impulse);

    case '4a'
        % 4.a.1
        fileName = fullfile(dataDirName,'impulse.mat');
        [planC,structNum] = preparePlanC(fileName);
        indexS = planC{end};
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID4a1.json');

        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_4a1'];

        %4.a.2
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID4a2.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_4a2'];

        planName = fullfile(outDir,'4a.mat');
        save_planC(planC,[],'PASSED',planName);
        exportScans(planName,outDir,'4a',metadataS.impulse);

    case '4b'
        %4.b.1
        fileName = fullfile(dataDirName,'sphere.mat');
        [planC,structNum] = preparePlanC(fileName);
        indexS = planC{end};
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID4b1.json');

        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_4b1'];

        %4.b.2
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID4b2.json');
        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_4b2'];

        planName = fullfile(outDir,'4b.mat');
        save_planC(planC,[],'PASSED',planName);
        exportScans(planName,outDir,'4b',metadataS.sphere);

    case '5a'
        % 5.a.1
        fileName = fullfile(dataDirName,'impulse.mat');
        [planC,structNum] = preparePlanC(fileName);
        indexS = planC{end};
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID5a1.json');

        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'_5a1'];

        % 5.a.2
        %paramFile = fullfile(configDirName,'IBSIPhase2-1ID5a2.json');
        %planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        %scanNum = length(planC{indexS.scan});
        %planC{indexS.scan}(scanNum).scanType = ...
        %   [planC{indexS.scan}(scanNum).scanType,'_5a2'];

        planName = fullfile(outDir,'5a.mat');
        save_planC(planC,[],'PASSED',planName);
        exportScans(planName,outDir,'5a',metadataS.impulse);

    case '6a'
        % 6.a.1
        fileName = fullfile(dataDirName,'sphere.mat');
        [planC,structNum] = preparePlanC(fileName);
        indexS = planC{end};
        paramFile = fullfile(configDirName,'IBSIPhase2-1ID6a1.json');

        planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
        scanNum = length(planC{indexS.scan});
        planC{indexS.scan}(scanNum).scanType = ...
            [planC{indexS.scan}(scanNum).scanType,'6a1'];

        %6.a.2
        %paramFile = fullfile(configDirName,'IBSIPhase2-1ID6a2.json');
        %planC = generateTextureMapFromPlanC(planC,structNum,paramFile);
        %scanNum = length(planC{indexS.scan});
        %planC{indexS.scan}(scanNum).scanType = ...
        %    [planC{indexS.scan}(scanNum).scanType,'6a2'];

        planName = fullfile(outDir,'6a.mat');
        save_planC(planC,[],'PASSED',planName);
        exportScans(planName,outDir,'6a',metadataS.sphere);

%     case '7a'
%         %7.a.1
%         fileName = fullfile(dataDirName,'checkerboard.mat');
%         [planC,structNum] = preparePlanC(fileName);
%         indexS = planC{end};
%         paramFile = fullfile(configDirName,'IBSIPhase2-1ID7a1.json');
% 
%         planC = generateTextureMapFromPlanC(planC,[],structNum,paramFile);
%         scanNum = length(planC{indexS.scan});
%         planC{indexS.scan}(scanNum).scanType = ...
%             [planC{indexS.scan}(scanNum).scanType,'7a1'];
% 
%         planName = fullfile(outDir,'7a.mat');
%         save_planC(planC,[],'PASSED',planName);
%         exportScans(planName,outDir,'7a',metadataS.sphere);

    case 'all'
        %Run all (default)
        configC = {'1a','1b','2a','2b','2c','3a','3b','3c',...
            '4a','4b','5a','6a'};%,'7a'};
        for iConf = 1:length(configC)
            runIBSI2benchmarkFilters(outDir,configC{iConf});
        end

    otherwise
        error('Invalid config %s',config)

end


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
        idxS = planC{end};
        strC = {planC{idxS.structures}.structureName};
        structNum = getMatchingIndex('wholeScan',strC,'EXACT');
    end

    function exportScans(planName,outDir,outFname,infoS)
        plan2C = loadPlanC(planName,tempdir);
        plan2C = updatePlanFields(plan2C);
        plan2C = quality_assure_planC(planName,plan2C);
        idxS = plan2C{end};
        nScans = length(plan2C{idxS.scan});
        for m = 2:nScans
            %Get texture map
            scan3M = double(getScanArray(m,plan2C));
            CToffset = plan2C{idxS.scan}(m).scanInfo(1).CTOffset;
            scan3M = scan3M - double(CToffset);
            %Flip dim
            scan3M = flip(permute(scan3M,[2,1,3]),3);
            %Write to .nii file
            saveName = [outFname,num2str(m-1),'.nii'];
            niftiwrite(scan3M,fullfile(outDir,saveName),infoS);
        end
    end

end
