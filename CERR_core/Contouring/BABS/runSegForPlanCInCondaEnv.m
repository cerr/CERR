function planC = runSegForPlanCInCondaEnv(planC,sessionPath,algorithm,...
    condaEnvList,wrapperFunctionList,batchSize)
% function planC = runSegForPlanCInCondaEnv(planC,sessionPath,algorithm,...
%     condaEnvList,wrapperFunctionList,batchSize)
%
% This function is a wrapper to run DL-segmentation models in Conda environments.
% -------------------------------------------------------------------------------
% INPUTS:
% planC
% sessionPath  -  Directory for writitng temporary segmentation metadata.
% algorithm    -  Algorthim name. For full list, see:
%                   https://github.com/cerr/CERR/wiki/Auto-Segmentation-models.
%                 Pass caret-delimited list to chain multilple algorithms, e.g:
%                   algorithm = ['CT_ChewingStructures_DeepLabV3^',...
%                   'CT_Larynx_DeepLabV3^CT_PharyngealConstrictor_DeepLabV3'];
% condaEnvList -  String containing caret-separated names of conda env.
%                 It can also be a cell-array of conda environment names.
%                 It is obtained from getSegWrapperFunc if not specified or empty
%                 Specify absolute paths of Conda environmnents. If names are specified,
%                 the location of conda installation must be defined in CERROptions.json.
%                 "condaPath" : "C:/Miniconda3/"
%                 The environment muust contain subdirectory 'condabin', "activate" script
%                 and subdirectory 'envs'.
% wrapperFunctionList (optional)
%              - String containing caret-separated absolute paths of wrapper functions.
%                It can also be a cell-array of strings.
%                If not specified or empty, the names of wrapper functions
%                are obtained from getSegWrapperFunc.m.
% batchSize (optional)
%              -  Batch size for inference (default : 4).
%
%--------------------------------------------------------------------------------
% EXAMPLE:
% To run segmentation, open a CERR-format file using the GUI or command-line, followed by:
%
%   global planC % to access metadata from CERR Viewer
%   sessionPath = '/path/to/session/dir';
%   algorithm = 'CT_Heart_DeepLab';
%   condaEnvName = '/path/to/condaEnv/testEnv';
%   wrapperFunctionList = '/path/to/wrapperFunction/testWrapper.py';
%   batchSize = 1;
%   planC = runSegForPlanCInCondaEnv(planC,sessionPath,algorithm,condaEnvName,...
%   wrapperFunctionList,batchSize);
%--------------------------------------------------------------------------------
%
% AI, 09/21/2020

global stateS

%% Parse algorithm & functionName and convert to cell arrray
if iscell(algorithm)
    algorithmC = algorithm;
else
    algorithmC = strsplit(algorithm,'^');
end
numAlgorithms = numel(algorithmC);

%% Get list of conda envs for each algorithm
if iscell(condaEnvList)
    condaEnvListC = condaEnvList;
else
    condaEnvListC = strsplit(condaEnvList,'^');
end
numContainers = numel(condaEnvListC);
if numAlgorithms > 1 && numContainers == 1
    condaEnvListC = repmat(condaEnvListC,numAlgorithms,1);
elseif numAlgorithms ~= numContainers
    error('Mismatch between no. specified algorithms and conda envs.')
end


%% Get wrapper function names for algorithm/condaEnvs
if ~exist('wrapperFunctionList','var') || isempty(wrapperFunctionList)
    functionNameC = getSegWrapperFunc(condaEnvListC,algorithmC);
elseif iscell(wrapperFunctionList)
    functionNameC = wrapperFunctionList;
else
    functionNameC = strsplit(wrapperFunctionList,'^');
end
numContainers = numel(functionNameC);
if numAlgorithms > 1 && numContainers == 1
    functionNameC = repmat(functionNameC,numAlgorithms,1);
elseif numAlgorithms ~= numContainers
    error('Mismatch between no. specified algorithms and wrapper functions')
end

if ~exist('batchSize','var')||isempty(batchSize)
    batchSize = 4; %Default batch size
end


%% Loop over algorithms
% Resolve error by setting KMP_DUPLICATE_LIB_OK' to 'TRUE'
% OMP: Error #15: Initializing libiomp5md.dll, but found libiomp5md.dll already initialized.
% https://community.intel.com/t5/Intel-Integrated-Performance/Solution-to-Error-15-Initializing-libiomp5md-dll-but-found/td-p/800649
setenv('KMP_DUPLICATE_LIB_OK','TRUE')
pth = getenv('PATH');
for k =1:length(algorithmC)
    
        %Prepare data for segmentation
    [fullSessionPath,activate_cmd,run_cmd,userOptS,~,scanNumV,planC] = ...
        prepDataForSeg(planC,sessionPath,algorithmC(k),condaEnvListC(k),...
        functionNameC(k),batchSize);
    
    cmd = [activate_cmd,' && ',run_cmd];
    disp(cmd)
    tic
    status = system(cmd);
    toc
    
    %Set Environment variables to default
    setenv('PATH',pth)
    
    %Post-process masks and import to CERR
    planC = processAndImportSeg(planC,scanNumV,fullSessionPath,userOptS);
    
end

% Remove session directory
rmdir(fullSessionPath, 's')

% Refresh Viewer
if ~isempty(stateS) && (isfield(stateS,'handle') && ishandle(stateS.handle.CERRSliceViewer))
    stateS.structsChanged = 1;
    CERRRefresh
end

end