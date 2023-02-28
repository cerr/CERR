function runIBSI2benchmarkStatistics(outDir,phase)
% Usage: runIBSI2benchmarkStatistics(outDir,phase);
% -----------------------------------------------------------------------
% Inputs
% outDir       : Path to output directory.
% phase        : 2 or 3
% -----------------------------------------------------------------------
% AI 11/23/2022
% Ref: https://arxiv.org/pdf/2006.05470.pdf (Table 6.2)

basePath = getCERRPath;
idxV = strfind(getCERRPath,filesep);

cerrPath = getCERRPath;
switch(phase)

    case 2
        templateFile = fullfile(basePath(1:idxV(end-1)),'Unit_Testing',...
            'settings_for_comparisons','IBSI-2-Phase2-Submission-Template.csv');
        paramFilePrefix = 'IBSIPhase2-2ID';
        settingsC = {'1a','1b','2a','2b','3a','3b'};%,'4a','4b',...
            %'5a','5b','6a','6b'};

        dataDirName = fullfile(cerrPath(1:idxV(end-1)),...
            'Unit_Testing\data_for_cerr_tests\IBSI2_CT_phantom');
        dataDirS = dir([dataDirName,filesep,'*.mat']);
        fileNameC = {[dataDirName,filesep,dataDirS(1).name]};
        niiDataDir = fullfile(cerrPath(1:idxV(end-1)),...
            ['Unit_Testing\data_for_cerr_tests\IBSI2_CT_phantom\',...
            'CT_radiomics_phantom\image']);
        niiDataDirC = {niiDataDir};
        modC = {'CT'};

        outFile ='IBSIphase2-2';
        statStartLine = 7;


    case 3
        templateFile = fullfile(basePath(1:idxV(end-1)),'Unit_Testing',...
            'settings_for_comparisons','IBSI-2-Phase3-Submission-Template.csv');
        paramFilePrefix = 'IBSIPhase2-3ID';
        settingsC = {'1','2','3','4','5','6'};
        subC = {'a','b','c'};

        dataDirName = fullfile(cerrPath(1:idxV(end-1)),...
            'Unit_Testing\data_for_cerr_tests\IBSI2_multimodal_data');
        dataDirS = dir([dataDirName,filesep,'*.mat']);
        fileNameC = {dataDirS.name};
        fileNameC = strcat([dataDirName,filesep],fileNameC);
        niiDataDir = fullfile(cerrPath(1:idxV(end-1)),...
            'Unit_Testing\data_for_cerr_tests\IBSI2_multimodal_data\'); ...
        niiDataDirS = dir(niiDataDir);
        niiDataDirS(1:2) = [];
        dirListC = {niiDataDirS([niiDataDirS.isdir]).name};
        niiDataDirC = strcat(niiDataDir,dirListC);
        modC = {'CT','MR_T1','PET'};

        outFile ='IBSIphase2-3';
        statStartLine = 2;

end

%Read output template
rawC = csv2cell(templateFile);
outC = rawC;
for line = 2:length(rawC)
    tempLine = rawC{line};
    idxV = strfind(tempLine,';');
    outC{line} = tempLine(1:idxV(4)-1);
end

% Path to config. file
idxV = strfind(getCERRPath,filesep);
configDirName = fullfile(cerrPath(1:idxV(end-1)),...
    'Unit_Testing\settings_for_comparisons');

% List required output fields
outFieldC = {'mean','var','skewness','kurtosis','median','min','P10',...
    'P90','max','interQuartileRange','range','meanAbsDev',...
    'robustMeanAbsDev','medianAbsDev','coeffVariation',...
    'coeffDispersion','energy','rms'};
diagFieldC = {'NumVoxOrig','numVoxelsInterpReseg',...
    'MeanIntensityInterpReseg','MaxIntensityInterpReseg',...
    'MinIntensityInterpReseg'};
numStats = length(outFieldC);
numDiag = length(diagFieldC);
sheet = 1;

%% Compute response maps
for nFile = 1:length(fileNameC)

    %Load CERR file
    planC = preparePlanC(fileNameC{nFile});
    indexS = planC{end};
    niiDataDir = niiDataDirC{nFile};

    for nMod = 1:length(modC)

        %Get struct no.
        if phase == 2
            strName = 'ROI'; %Change?
        else
            strName = [modC{nMod},'_ROI'];
        end
        scanNum = nMod;
        strC = {planC{indexS.structures}.structureName};
        structNum = getMatchingIndex(strName,strC,'EXACT');

        %Define output filename
        if phase==2
            outFileName = outFile;
        else
            [~,id,~] = fileparts(fileNameC{nFile});
            outFileName = [outFile,'_',id,'_',modC{nMod}];
        end
        outFileName = fullfile(outDir,[outFileName,'.csv']);

        %Loop over configurations
        featM = nan(numStats,length(settingsC));
        featC = cell(numStats,length(settingsC));
        diagC = cell(numDiag,length(settingsC));
        for setting = 1:length(settingsC)

            %Read config. file
            if phase==2
                paramFile = fullfile(configDirName,[paramFilePrefix,...
                    settingsC{setting},'.json']);
            else
                paramFile = fullfile(configDirName,[paramFilePrefix,...
                    settingsC{setting},subC{nMod},'.json']);
            end

            %Calc. features
            paramS = getRadiomicsParamTemplate(paramFile);
            [cerrFeatS,diagS] = calcGlobalRadiomicsFeatures...
                (scanNum, structNum, paramS, planC);

            %Convert diagnositc features to cell
            diagValC = struct2cell(diagS);
            diagC(:,setting) = diagValC;

            %Retain required fields (statistics)
            imgType = fieldnames(cerrFeatS);
            featS = cerrFeatS.(imgType{1}).firstOrderS;
            featS = filterFields(featS,outFieldC);
            %featM(:,setting) = cell2mat(struct2cell(featS));
            featC(:,setting) = struct2cell(featS);
        end

        %Record diagnostic features
        if phase==2
            diagC = cellfun(@num2str,diagC,'un',0);
            tempDiagC = [outC(2:statStartLine-1),diagC];
            outDiagC = cell(statStartLine-1,1);
            outDiagC{1} = outC{1};
            for line = 2:statStartLine-1
                tempDiag = strjoin(tempDiagC(line-1,:),';');
                outDiagC{line} = tempDiag;
            end
        else
               outDiagC = outC;
        end

        featC = cellfun(@num2str,featC,'un',0);
        tempC = [outC(statStartLine:end),featC];
        outValC = outDiagC;
        headerC = outValC(1,:);
        numCols = length(strsplit([headerC{:}],';'));

        for line = 2:statStartLine-1
            lineC = outValC(line,:);
            numColsLine = length(strsplit([lineC{:}],';'));
            outValC{line} =  [outValC{line},...
                repmat(';',[1,numCols - numColsLine])];
        end

        for line = statStartLine:length(outC)
            outValC{line} = strjoin(tempC(line-statStartLine+1,:),';');
            %Handle missing configurations
            lineC = outValC(line,:);
            numColsLine = length(strsplit([lineC{:}],';'));
            outValC{line} = [outValC{line},...
                repmat(';',[1,numCols - numColsLine])];
            %outValC{line} = [outValC{line},';;;;']; %TEMP
            %outValC{line} = [outValC{line},';;;;;;;;;;']; %Missing configs
        end
        %outValC = cellfun(@(x)strsplit(x,';'),outValC,'un',0);
        outValC = cellfun(@(x)strrep(x,';',','),outValC,'un',0);

        %sheet = nMod;
        %outFileName = strrep(outFileName,'IBSIphase2-3_','');
        %cell2csv(outValC,outFileName);
        cell2file(outValC,outFileName);
    end
end


%% -- Supporting functions --

    function planC = preparePlanC(fileName)
        planC = loadPlanC(fileName,tempdir);
        planC = updatePlanFields(planC);
        planC = quality_assure_planC(fileName,planC);
    end


    function outS = filterFields(inS,keepFieldC)

        for k = 1:length(keepFieldC)
            outS.(keepFieldC{k}) = inS.(keepFieldC{k});
        end

    end

end
