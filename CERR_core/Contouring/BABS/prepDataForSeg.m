function [fullSessionPath,activate_cmd,run_cmd,userOptS,outFile,scanNumV,planC] = ...
    prepDataForSeg(planC,sessionPath,algorithm,condaEnv,wrapperFunction,batchSize)
% [fullSessionPath,activate_cmd,run_cmd,userOptS,outFile,scanNumV,planC] =
% prepDataForSeg(planC,sessionPath,algorithm,condaEnv,wrapperFunction,...
% batchSize)
%
% This wrapper prepares data for DL-based segmentation
% -------------------------------------------------------------------------
% INPUTS:
% planC
% sessionPath  -  Directory for writitng temporary segmentation metadata.
% algorithm    -  Algorthim name. For full list, see:
%                 https://github.com/cerr/CERR/wiki/Auto-Segmentation-models.
% condaEnv     -  String containing absolute path to conda environment.
%                 If env name is provided, the location of conda installation
%                 must be defined in CERROptions.json (e.g. "condaPath" :
%                 "C:/Miniconda3/"). The environment muust contain
%                 subdirectories 'condabin', and 'envs' as well as script
%                 "activate".
%                 Note: CondaEnv is obtained from getSegWrapperFunc if not
%                 specified or empty.
% wrapperFunction (optional)
%              - String containing absolute path of wrapper function.
%                If not specified or empty, wrapper function is obtained
%                from getSegWrapperFunc.m.
% batchSize (optional)
%              -  Batch size for inference (default : 4).
%--------------------------------------------------------------------------------
% AI, 09/21/2021

%% Create session directory for segmentation metadata
indexS = planC{end};
% Create temp. dir labelled by series UID, local time and date
if isfield(planC{indexS.scan}(1).scanInfo(1),'seriesInstanceUID') && ...
        ~isempty(planC{indexS.scan}(1).scanInfo(1).seriesInstanceUID)
    folderNam = planC{indexS.scan}(1).scanInfo(1).seriesInstanceUID;
else
    %folderNam = dicomuid;
    orgRoot = '1.3.6.1.4.1.9590.100.1.2';
    folderNamJava = javaMethod('createUID','org.dcm4che3.util.UIDUtils',orgRoot);
    folderNam = folderNamJava.toCharArray';
end
dateTimeV = clock;
randNum = 1000.*rand;
sessionDir = ['session',folderNam,num2str(dateTimeV(4)), num2str(dateTimeV(5)),...
    num2str(dateTimeV(6)), num2str(randNum)];
fullSessionPath = fullfile(sessionPath,sessionDir);


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
testFlag = true;

%Set default batch size
if ~exist('batchSize','var')||isempty(batchSize)
    batchSize = 4; 
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

if ~iscell(condaEnv)
    condaEnvC = {condaEnv};
else
    condaEnvC = condaEnv;
end


if ~exist('wrapperFunction','var') || isempty(wrapperFunction)
    wrapperFunction = getSegWrapperFunc(condaEnvC,algorithmC);
end

%% Data pre-processing

%Read config file
configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary',...
    'SegmentationModels', 'ModelConfigurations',[algorithmC{1},...
    '_config.json']);
userOptS = readDLConfigFile(configFilePath);

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
if ~exist('batchSize','var') || isempty(batchSize)
    batchSize = userOptS.batchSize;
end
[scanC, maskC, scanNumV, userOptS, coordInfoS, planC] = ...
    extractAndPreprocessDataForDL(userOptS,planC,testFlag);
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
    idS = scanOptS(nScan).identifier;
    idListC = cellfun(@(x)(idS.(x)),fieldnames(idS),'un',0);
    appendStr = strjoin(idListC,'_');
    idOut = [filePrefixForHDF5,'_',appendStr];
    
    %Get o/p dirs & dim
    outDirC = getOutputH5Dir(modInputPath,scanOptS(nScan),'');
    
    %Write to model input fmt
    writeDataForDL(scanC{nScan},maskC{nScan},coordInfoS,passedScanDim,...
        modelFmt,outDirC,idOut,testFlag);
end

% Get path to activation script
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
    activate_cmd = sprintf('source %s',condaSrc);
end
run_cmd = sprintf('python %s %s %s %s',wrapperFunction{1}, modInputPath,...
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


end