function runIBSI2benchmarkStatistics(outDir)
% Usage: runIBSI2benchmarkStatistics(outDir);
% -----------------------------------------------------------------------
% Inputs
% outDir       : Path to output directory.
% -----------------------------------------------------------------------
% AI 11/23/2022
% Ref: https://arxiv.org/pdf/2006.05470.pdf (Table 6.2)

basePath = getCERRPath;
idxV = strfind(getCERRPath,filesep);
templateFile = fullfile(basePath(1:idxV(end-1)),'Unit_Testing',...
    'settings_for_comparisons','IBSI-2-Phase2-Submission-Template.csv');
[~,~,rawC] = xlsread(templateFile);
outC = rawC;
for line = 2:length(rawC)
    tempLine = rawC{line};
    idxV = strfind(tempLine,';');
    outC{line} = tempLine(1:idxV(4)-1);
end

%% Path to IBSI phase-2 CT phantom 
cerrPath = getCERRPath;
idxV = strfind(getCERRPath,filesep);
dataDirName = fullfile(cerrPath(1:idxV(end-1)),...
    'Unit_Testing\data_for_cerr_tests\IBSI2_CT_phantom');
configDirName = fullfile(cerrPath(1:idxV(end-1)),...
    'Unit_Testing\settings_for_comparisons');
fileName = fullfile(dataDirName,'ibsi_2_ct_radiomics_phantom.mat');

%% Get metadata
niiDataDir = fullfile(cerrPath(1:idxV(end-1)),...
    'Unit_Testing\data_for_cerr_tests\IBSI2_CT_phantom\CT_radiomics_phantom\image');
metadataS = getMetadata(niiDataDir,'phantom');

%% List required output fields
outFieldC = {'mean','var','skewness','kurtosis','median','min','P10',...
    'P90','max','interQuartileRange','range','meanAbsDev',...
    'robustMeanAbsDev','medianAbsDev','coeffVariation',...
    'coeffDispersion','energy','rms'};
diagFieldC = {'NumVoxOrig'};
numStats = length(outFieldC);
statStartLine = 7;
sheet = 1;

settingsC = {'1a','1b','2a','2b','3a','3b','4a','4b','5a','5b','6a','6b'};

%% Compute response maps
[planC,structNum] = preparePlanC(fileName);
indexS = planC{end};
scanNum = 1;

%Loop over configurations
featM = nan(numStats,length(settingsC));
featC = cell(numStats,length(settingsC));
for setting = 1:length(settingsC)

    %2.a
    %Read config. file
    paramFile = fullfile(configDirName,['IBSIPhase2-2ID',...
        settingsC{setting},'.json']);

    %Calc. features
    paramS = getRadiomicsParamTemplate(paramFile);
    [cerrFeatS,diagS] = calcGlobalRadiomicsFeatures...
        (scanNum, structNum, paramS, planC);

    %Convert diagnositc features to cell
    diagC(:,setting) = struct2cell(diagS);

    %Retain required fields (statistics)
    imgType = fieldnames(cerrFeatS);
    featS = cerrFeatS.(imgType{1}).firstOrderS;
    featS = filterFields(featS,outFieldC);
    %featM(:,setting) = cell2mat(struct2cell(featS));
    featC(:,setting) = struct2cell(featS);
end
diagC = cellfun(@num2str,diagC,'un',0);
tempDiagC = [outC(2:statStartLine-1),diagC];
featC = cellfun(@num2str,featC,'un',0);
tempC = [outC(statStartLine:end),featC];

for line = 2:statStartLine-1
    tempDiag = strjoin(tempDiagC(line-1,:),';');
    outC{line} = tempDiag;
end
for line = statStartLine:length(outC)
    outC{line} = strjoin(tempC(line-statStartLine+1,:),';');
end

%Write to file
fileName = fullfile(outDir,'IBSIphase2-2.csv');
writecell(outC,fileName);
%writematrix(featM,fileName,Name,Value)

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
        structNum = getMatchingIndex('ROI',strC,'EXACT');
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

    function outS = filterFields(inS,keepFieldC)

        for k = 1:length(keepFieldC)
            outS.(keepFieldC{k}) = inS.(keepFieldC{k});
        end

    end

end
