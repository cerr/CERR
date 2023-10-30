function [activate_cmd,run_cmd,userOptS,outFile,origScanNumV,scanNumV,planC] = ...
    prepDataForAImodel(planC,fullSessionPath,algorithm,cmdFlag,newSessionFlag,...
    containerPath,wrapperFunction,skipMaskExport,inputIdxS)
% [activate_cmd,run_cmd,userOptS,outFile,scanNumV,planC] =
% prepDataForSeg(planC,sessionPath,algorithm,cmdFlag,containerPath,...
% wrapperFunction,batchSize)
%
% This wrapper prepares data for DL-based segmentation
% -------------------------------------------------------------------------
% INPUTS:
% planC        -  planC OR path to dir containing CERR files.
% sessionPath  -  Directory for writitng temporary segmentation metadata.
% algorithm    -  Algorthim name. For full list, see:
%                 https://github.com/cerr/CERR/wiki/Auto-Segmentation-models.
% cmdFlag       -  "condaEnv" or "singContainer"
% newSessionFlag- Set to false to use existing dir (default: true).
% containerPath -  * If cmdFlag is "condaEnv": containerPath must be a string
%                 containing the absolute path to a conda environment.
%                 If env name is provided, the location of conda installation
%                 must be defined in CERROptions.json (e.g. "condaPath" :
%                 "C:/Miniconda3/"). The environment muust contain
%                 subdirectories 'condabin', and 'envs' as well as script
%                 "activate".
%                 Note: CondaEnv is obtained from getSegWrapperFunc if not
%                 specified or empty.
%                 * If cmdFlag is "singContainer": containerPath must be a
%                 string containing the absolute path to a singularity
%                 container.
% wrapperFunction (optional)
%              - String containing absolute path of wrapper function.
%                If not specified or empty, wrapper function is obtained
%                from getSegWrapperFunc.m.
% skipMaskExport (optional)
%              - Set to false if model requires segmentation masks as input.
%                Default: true.
% inputIdxS (optional)
%              - Dictionary of scan/structure nos. 
%                Default: Use identifiers from optS. 
%--------------------------------------------------------------------------------
% AI, 09/21/2021

%To create session directory for segmentation metadata, use:
%fullSessionPath = createSessionForDLSeg(sessionPath,planC);

%% Create sub-directories
if newSessionFlag
    %-For CERR files
    mkdir(fullSessionPath)
    cerrPath = fullfile(fullSessionPath,'dataCERR');
    mkdir(cerrPath)
    outputCERRPath = fullfile(fullSessionPath,'outputOrigCERR');
    mkdir(outputCERRPath)
    AIResultCERRPath = fullfile(fullSessionPath,'AIResultCERR');
    mkdir(AIResultCERRPath)
    %-For structname-to-label map
    AIoutputPath = fullfile(fullSessionPath,'AIoutput');
    mkdir(AIoutputPath);
end
%-For shell script
AIscriptPath = fullfile(fullSessionPath,'AIscript');
mkdir(AIscriptPath)

if ~exist('skipMaskExport','var')
    skipMaskExport = true;
end

%% Get conda installation path
optS = opts4Exe([getCERRPath,'CERROptions.json']);
condaPath = optS.condaPath;

%% Get wrapper function names for algorithm/condaEnv
if ~iscell(algorithm)
    algorithmC = {algorithm};
else
    algorithmC = algorithm;
end

%% Data pre-processing
%Read config file
configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary',...
    'SegmentationModels', 'ModelConfigurations',[algorithmC{1},...
    '_config.json']);
userOptS = readDLConfigFile(configFilePath);

%Copy to session dir
copyfile(configFilePath,fullSessionPath);

%Get batch size
batchSize = userOptS.batchSize;

%Clear previous contents of session dir
modelFmt = userOptS.modelInputFormat;
modInputPath = fullfile(fullSessionPath,['input',modelFmt]);
modOutputPath = fullfile(fullSessionPath,['output',modelFmt]);
if exist(modInputPath, 'dir')
    rmdir(modInputPath, 's')
end
mkdir(modInputPath);
if exist(modOutputPath, 'dir')
    rmdir(modOutputPath, 's')
end
mkdir(modOutputPath);

%% Get input data types
inputS = userOptS.input;
inputC = fieldnames(inputS);

inputScanNumV = [];
inputStrV = [];
if ~isempty(inputIdxS)
    if isfield(inputIdxS,'scan')
        val = inputIdxS.scan.scanNum;
        if all(isnumeric(val)) && ~any(isnan(val))
            inputScanNumV = val;
        end
    end
    if isfield(inputIdxS,'structure')
        val = inputIdxS.structure.strNum;
        if all(isnumeric(val)) && ~any(isnan(val))
            inputStrV = val;
        end
    end
end
        
 
%% Pre-process data and export to model input fmt
if iscell(planC)
    indexS = planC{end};
    filePrefixForHDF5 = 'cerrFile';
    
    %Update cropping structure index where needed
    if isfield(userOptS.input,'structure')
        maskStrC = {userOptS.input.structure.name};
        allStrC = {planC{indexS.structures}.structureName};
        if isfield(userOptS.input.scan,'crop')
            for nScan = 1:length(userOptS.input.scan)
                cropS = userOptS.input.scan(nScan).crop;
                if ~(length(cropS) == 1 && strcmpi(cropS(1).method,'none'))
                    cropStrListC = arrayfun(@(x)x.params.structureName,cropS,'un',0);
                    cropParS = [cropS.params];
                    if ~isempty(cropStrListC)
                        for nCropStr = 1:length(cropStrListC)
                            if strcmpi(cropStrListC{nCropStr},maskStrC{nCropStr})
                                outStrName = allStrC{inputStrV(nCropStr)};
                                cropParS(nCropStr).structureName = outStrName;
                            end
                        end
                        cropS.params = cropParS;
                    end
                end
                userOptS.input.scan(nScan).crop = cropS;
            end
            end
    end
    
    for nIn = 1:length(inputC)
        
        inputType = inputC{nIn};

        switch(inputType)

            case {'scan','structure'}

                exportScan = 1;
                if strcmpi(inputType,'structure')
                    indexS = planC{end};
                    if ~isempty(inputStrV)
                        strNameC = {planC{indexS.structures}(inputStrV).structureName};
                    elseif isfield(inputS.structure,'name')
                        strNameC = inputS.structure.name;
                    elseif isfield(inputS.structure,'strNameToLabelMap')
                        strNameC = ...
                            {inputS.structure.strNameToLabelMap.structureName};
                    end

                    if ~iscell(strNameC)
                        strNameC = {strNameC};
                    end
                    %For structures associated with scans input to the
                    %model export is handled in extractAndPreprocessDataForDL
                    %below
                    strC = {planC{indexS.structures}.structureName};
                    strNumV = nan(1,length(strNameC));
                    for nStr = 1:length(strNameC)
                        strNum = getMatchingIndex(strNameC{nStr},strC,'EXACT');
                        strNumV(nStr) = strNum(1);
                    end
                    assocScanV = getStructureAssociatedScan(strNumV,planC);
                    skipIdxV = ismember(assocScanV,inputScanNumV);
                    strNumV = strNumV(~skipIdxV);
                    if sum(skipIdxV)==length(assocScanV)
                        exportScan = 0;
                        continue
                    end
                    
                    scanC = {};
                    for nStr = 1:length(strNumV)
                        strMaskC{nStr} = getStrMask(strNumV(nStr),planC);
                    end
                    maskC{1} = strMaskC;
                    
                end

                if exportScan

                    %Pre-process data and export to model input fmt
                    fprintf('\nPre-processing data...\n');
                    assocScanV = getStructureAssociatedScan(inputStrV,planC);
                    keepIdxV = ismember(assocScanV,inputScanNumV);
                    expStrV = inputStrV(keepIdxV);
                    [scanC, maskC, origScanNumV, scanNumV, userOptS,...
                        coordInfoS, planC] = ...
                        extractAndPreprocessDataForDL(userOptS,planC,...
                        skipMaskExport,inputScanNumV,expStrV);
                end

                %Export to model input format
                tic
                fprintf('\nWriting to %s format...\n',modelFmt);
                passedScanDim = userOptS.passedScanDim;
                scanOptS = userOptS.input.scan;

                %Loop over scan types
                for nScan = 1:size(scanC,1)

                    %Append identifiers to o/p name
                    idOut = getOutputFileNameForDL(filePrefixForHDF5,...
                        scanOptS(nScan),scanNumV(nScan),planC);

                    %Get o/p dirs & dim
                    outDirC = getOutputH5Dir(modInputPath,scanOptS(nScan),'');

                    %Write to model input fmt
                    writeDataForDL(scanC{nScan},maskC{nScan},coordInfoS,...
                        passedScanDim,modelFmt,outDirC,idOut,skipMaskExport);
                end

                %case 'dose'

            otherwise
                error('Invalid input type '' %s ''.')
        end
    end
else
    cerrFilePath = planC;
    planCfileS = dir(fullfile(cerrFilePath,'*.mat'));
    planCfiles = {planCfileS.name};

    for nFile=1:length(planCfileS)

        % Load plan
        [~,ptName,~] = fileparts(planCfiles{nFile});
        fileNam = fullfile(cerrFilePath,planCfiles{nFile});
        planC = loadPlanC(fileNam, tempdir);
        planC = quality_assure_planC(fileNam,planC);
        
        %Update cropping structure index where needed
        maskStrC = {};
        if isfield(userOptS.input,'structure')
            if isfield(userOptS.input.structure,'name')
                maskStrC = {userOptS.input.structure.name};
            else
                if isfield(userOptS.input.structure,'strNameToLabelMap')
                    maskStrC = {userOptS.input.structure.strNameToLabelMap.structureName};
                end
            end
        end
        indexS = planC{end};
        allStrC = {planC{indexS.structures}.structureName};
        if isfield(userOptS.input.scan,'crop')
            for nScan = 1:length(userOptS.input.scan)
                cropS = userOptS.input.scan(nScan).crop;
                if ~(length(cropS) == 1 && strcmpi(cropS(1).method,'none'))
                    cropStrListC = arrayfun(@(x)x.params.structureName,cropS,'un',0);
                    cropParS = [cropS.params];
                    if ~isempty(cropStrListC)
                        for nCropStr = 1:length(cropStrListC)
                            if ~isempty(maskStrC) && strcmpi(cropStrListC{nCropStr},maskStrC{nCropStr})
                                outStrName = allStrC{inputStrV(nCropStr)};
                                cropParS(nCropStr).structureName = outStrName;
                            end
                        end
                        cropS.params = cropParS;
                    end
                end
                userOptS.input.scan(nScan).crop = cropS;
            end
        end

        %Pre-process data and export to model input fmt
        filePrefixForHDF5 = ['cerrFile^',ptName];
        for nIn = 1:length(inputC)

            inputType = inputC{nIn};

            switch(inputType)
                
                case {'scan','structure'}
                    
                    exportScan = 1;
                    if strcmpi(inputType,'structure')
                        indexS = planC{end};
                        if isfield(inputS.structure,'name')
                            strNameC = inputS.structure.name;
                        else
                            if isfield(inputS.structure,'strNameToLabelMap')
                                strNameC = {inputS.structure.strNameToLabelMap.structureName};
                            end
                        end
                        if ~iscell(strNameC)
                            strNameC = {strNameC};
                        end
                        %For structures associated with scans input to the
                        %model export is handled in extractAndPreprocessDataForDL
                        %below
                        strC = {planC{indexS.structures}.structureName};
                        strNumV = nan(1,length(strNameC));
                        for nStr = 1:length(strNameC)
                            strNum = getMatchingIndex(strNameC{nStr},strC,'EXACT');
                            strNumV(nStr) = strNum(1);
                        end
                        assocScanV = getStructureAssociatedScan(strNumV,planC);
                        skipIdxV = ismember(assocScanV,scanNumV);
                        strNumV = strNumV(~skipIdxV);
                        if sum(skipIdxV)==length(assocScanV)
                            exportScan = 0;
                            continue
                        end
                        
                        scanC = {};
                        for nStr = 1:length(strNumV)
                            strMaskC{nStr} = getStrMask(strNumV(nStr),planC);
                        end
                        maskC{1} = strMaskC;
                        
                    end
                    
                    if exportScan
                        %Pre-process data and export to model input fmt
                        fprintf('\nPre-processing data...\n');
                        [scanC, maskC, origScanNumV, scanNumV, userOptS,...
                            coordInfoS, planC] = ...
                            extractAndPreprocessDataForDL(userOptS,planC,...
                            skipMaskExport,inputScanNumV);
                    end
                    
                    %Export to model input format
                    tic
                    fprintf('\nWriting to %s format...\n',modelFmt);
                    passedScanDim = userOptS.passedScanDim;
                    scanOptS = userOptS.input.scan;
                    
                    %Loop over scan types
                    for nScan = 1:size(scanC,1)
                        
                        %Append identifiers to o/p name
                        idOut = getOutputFileNameForDL(filePrefixForHDF5,...
                            scanOptS(nScan),scanNumV(nScan),planC);
                        
                        %Get o/p dirs & dim
                        outDirC = getOutputH5Dir(modInputPath,scanOptS(nScan),'');
                        
                        %Write to model input fmt
                        writeDataForDL(scanC{nScan},maskC{nScan},coordInfoS,...
                            passedScanDim,modelFmt,outDirC,idOut,skipMaskExport);
                    end
                    
                    %case 'dose'
                    
                otherwise
                    error('Invalid input type '' %s ''.')
            end

        end

        %Save updated planC file
        tic
        save_planC(planC,[],'PASSED',fileNam);
        toc

    end
    planC = cerrFilePath;
end

%% Get run cmd
% Get wrapper functions if using conda env
switch lower(cmdFlag)

    case 'condaenv'
        if ~iscell(containerPath)
            condaEnvC = {containerPath};
        else
            condaEnvC = containerPath;
        end
        if ~exist('wrapperFunction','var') || isempty(wrapperFunction)
            wrapperFunction = getSegWrapperFunc(condaEnvC,algorithmC);
        end

        pth = getenv('PATH');
        condaBinPath = fullfile(condaPath,'condabin;');
        if ~isempty(strfind(condaEnvC{1},filesep)) %contains(condaEnv,filesep)
            condaEnvPath = condaEnvC{1};
            condaBinPath = fullfile(condaEnvC{1},'Scripts;');
        else
            condaEnvPath = fullfile(condaPath,'envs',condaEnvC{1});
        end

        if isempty(strfind(pth,condaBinPath))
            newPth = [condaBinPath,pth];
            setenv('PATH',newPth)
        end
        if ispc
            activate_cmd = sprintf('call activate %s',condaEnvC{1});
        else
            condaSrc = fullfile(condaEnvPath,'/bin/activate');
            activate_cmd = sprintf('/bin/bash -c "source %s',condaSrc);
        end
        run_cmd = sprintf('python %s %s %s %s"',wrapperFunction{1}, modInputPath,...
            modOutputPath,num2str(batchSize));

        %% Create script to call segmentation wrappers
        [uniqName,~] = genScanUniqName(planC, scanNumV(1));
        outFile = fullfile(AIscriptPath,[uniqName,'.sh']);
        fid = fopen(outFile,'wt');
        script = sprintf('#!/bin/zsh\n%s\nconda-unpack\npython --version\n%s',...
            activate_cmd,run_cmd);
        script = strrep(script,'\','/');
        fprintf(fid,script);
        fclose(fid);

    case 'singcontainer'

        activate_cmd = '';
        outFile = '';
        %Get the bind path for the container
        bindingDir = ':/scratch';
        bindPath = strcat(fullSessionPath,bindingDir);
        %Run container app
        run_cmd = sprintf('singularity run --app %s --nv --bind  %s %s %s',...
            algorithmC{1}, bindPath, containerPath, num2str(userOptS.batchSize));

end

end