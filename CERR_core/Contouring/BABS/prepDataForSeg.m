function [activate_cmd,run_cmd,userOptS,outFile,scanNumV,planC] = ...
    prepDataForSeg(planC,fullSessionPath,algorithm,cmdFlag,containerPath,...
    wrapperFunction,skipMaskExport)
% [activate_cmd,run_cmd,userOptS,outFile,scanNumV,planC] =
% prepDataForSeg(planC,sessionPath,algorithm,cmdFlag,containerPath,...
% wrapperFunction,batchSize)
%
% This wrapper prepares data for DL-based segmentation
% -------------------------------------------------------------------------
% INPUTS:
% planC
% sessionPath  -  Directory for writitng temporary segmentation metadata.
% algorithm    -  Algorthim name. For full list, see:
%                 https://github.com/cerr/CERR/wiki/Auto-Segmentation-models.
%cmdFlag       -  "condaEnv" or "singContainer"
%containerPath -  * If cmdFlag is "condaEnv": containerPath must be a string 
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
%--------------------------------------------------------------------------------
% AI, 09/21/2021

%To create session directory for segmentation metadata, use:
%fullSessionPath = createSessionForDLSeg(sessionPath,planC);

%% Create sub-directories
%-For CERR files
mkdir(fullSessionPath)
cerrPath = fullfile(fullSessionPath,'dataCERR');
mkdir(cerrPath)
outputCERRPath = fullfile(fullSessionPath,'segmentedOrigCERR');
mkdir(outputCERRPath)
segResultCERRPath = fullfile(fullSessionPath,'segResultCERR');
mkdir(segResultCERRPath)
%-For structname-to-label map
labelPath = fullfile(fullSessionPath,'outputLabelMap');
mkdir(labelPath);
%-For shell script
segScriptPath = fullfile(fullSessionPath,'segScript');
mkdir(segScriptPath)
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

% Pre-process and export data to HDF5 format
fprintf('\nPre-processing data...\n');
[scanC, maskC, scanNumV, userOptS, coordInfoS, planC] = ...
    extractAndPreprocessDataForDL(userOptS,planC,skipMaskExport);
%Note: mask3M is empty for testing

%Export to model input format
tic
fprintf('\nWriting to %s format...\n',modelFmt);
filePrefixForHDF5 = 'cerrFile';
passedScanDim = userOptS.passedScanDim;
scanOptS = userOptS.scan;

%Loop over scan types
for nScan = 1:size(scanC,1)
    
    %Append identifiers to o/p name
    idOut = getOutputFileNameForDL(filePrefixForHDF5,scanOptS(nScan),...
        scanNumV(nScan),planC);
    
    %Get o/p dirs & dim
    outDirC = getOutputH5Dir(modInputPath,scanOptS(nScan),'');
    
    %Write to model input fmt
    writeDataForDL(scanC{nScan},maskC{nScan},coordInfoS,passedScanDim,...
        modelFmt,outDirC,idOut,skipMaskExport);
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
        
        newPth = [condaBinPath,pth];
        setenv('PATH',newPth)
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
        outFile = fullfile(segScriptPath,[uniqName,'.sh']);
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