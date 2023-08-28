function success =  runAIforDicom(inputDicomPath,outputDicomPath,...
    sessionPath,algorithm,cmdFlag,savePlanc,varargin)
% function success = runSegForDicom(inputDicomPath,outputDicomPath,...
%   sessionPath,algorithm,varargin)
%
% This function serves as a wrapper for different types of segmentations.
%---------------------------------------------------------------------------------------
% INPUT:
% inputDicomPath  - path to input DICOM directory which needs to be segmented.
% outputDicomPath - path to write DICOM RTSTRUCT for resulting segmentation.
% sessionPath     - path to write temporary segmentation metadata.
% algorithm       - string which specifies segmentation algorithm
% cmdFlag         - "condaEnv" or "singContainer"
% savePlanC       - flag to write planC to file ("yes" or "no")
% --- Optional---
% varargin{1} - Path to segmentation container.
% varargin{2} - Scan no. (replaces input scan identifier)
% varargin{3} - Output assoc. scan no. (replaces output scan identifier)
% varargin{4} - Flag (true/false) to skip export of structure masks (default:true)
%              Set to false if model requires segmentation masks as input 
%%---------------------------------------------------------------------------------------
% Following directories are created within the session directory:
% --- ctCERR: contains CERR file/s of input DICOM.
% --- segmentedOrigCERR: CERR file with resulting segmentation fused with
% original CERR file.
% --- segResultCERR: CERR file with segmentation. Note that CERR file can
% be cropped based on initial segmentation.
%
% EXAMPLE: to run BABS segmentation
% inputDicomPath = '';
% outputDicomPath = '';
% sessionPath = '';
% algorithm = 'BABS';
% cmdFlag = 'singcontainer';
%savePlanc = 'yes'
% success = runSegForDicom(inputDicomPath,outputDicomPath,sessionPath,...
%           algorithm,babsPath);
% ------------------------------------------------------------------------------------
% APA, 12/14/2018
% RKP, 9/11/19 Updates for compatibility with training pipeline
% AI, 2/7/2020 Added separate DICOM export functions for BABS and DL algorithms
% AI, 3/5/2020 Updates to handle multiple algorithms
% AI, 8/12/22  Call runSegForPlanC

if nargin <=7
    scanNumV = [];
else
    scanNumV = varargin{2};
end
if nargin <=8
    assocScanNumV = [];
else
    assocScanNumV = varargin{3};
end
if nargin <=9
    skipMaskExport = true;
else
    if ischar(varargin{4})
        skipMaskExport = logical(eval(varargin{4}));
    else
        skipMaskExport = varargin{4};
    end
end

%% Create session directory to write segmentation metadata
if inputDicomPath(end) == filesep
    [~,folderNam] = fileparts(inputDicomPath(1:end-1));
else
    [~,folderNam] = fileparts(inputDicomPath);
end
dateTimeV = clock;
randStr = sprintf('%6.3f',rand*1000);
sessionDir = ['session',folderNam,num2str(dateTimeV(4)), num2str(dateTimeV(5)),...
    num2str(dateTimeV(6)), randStr];
fullSessionPath = fullfile(sessionPath,sessionDir);
while exist(fullSessionPath,'dir')
    randStr = sprintf('%6.3f',rand*1000);
    sessionDir = [sessionDir, randStr];
    fullSessionPath = fullfile(sessionPath,sessionDir);
end
 
% Create sub-directories 
%-For  CERR files
mkdir(fullSessionPath)
cerrPath = fullfile(fullSessionPath,'dataCERR');
mkdir(cerrPath)
outputCERRPath = fullfile(fullSessionPath,'outputOrigCERR');
mkdir(outputCERRPath)
AIresultCERRPath = fullfile(fullSessionPath,'AIResultCERR');
mkdir(AIresultCERRPath)
%-For structname-to-label map
AIoutputPath = fullfile(fullSessionPath,'AIoutput');
mkdir(AIoutputPath);

%% Import DICOM to CERR
init_ML_DICOM
importDICOM(inputDicomPath,cerrPath);

% Get container path
containerPath = varargin{1};

%% Run inference
newSessionFlag = false;
savePlancFlag = 0;
if strcmpi(savePlanc,'yes')
    savePlancFlag = 1;
end
if ~any(strcmpi(algorithm,'BABS'))

    %%  Run AI model
    [~,origScanNumV,outputScanNumV,allLabelNamesC,userOptS,dcmExportOptS] =...
        runAIforPlanC(cerrPath,fullSessionPath,algorithm,cmdFlag,newSessionFlag,[],[],...
        containerPath,scanNumV,assocScanNumV,skipMaskExport);

    %% Export result(s) to DICOM
    
    %Loop over model outputs
    outputC = fieldnames(userOptS.output);
    for nOut = 1:length(outputC)
        
        outType = outputC{nOut};
        
        switch(lower(outType))
            
            case 'labelmap'
                % Export segmentations to DICOM RTSTRUCT files
                fprintf('\nExporting to DICOM format...');
                tic
                batchExportAISegToDICOM(cerrPath,origScanNumV,allLabelNamesC,outputCERRPath,...
                    outputDicomPath,dcmExportOptS,savePlancFlag)
                toc
                
            case 'dvf'
                % Export segmentations to DICOM RTSTRUCT files
                
                dvfPath = userOptS.output.(outType).outputDir;
                dirS = dir(dvfPath);
                dvfFile = fullfile(dvfPath, dirS(3).name);
                
                fprintf('\nExporting to DICOM format...');
                tic
                batchExportAIRegToDICOM(cerrPath,origScanNumV,outputScanNumV,...
                    cmdFlag, containerPath, dvfFile, outputDicomPath,dcmExportOptS);
                toc
                
        end
        
    end
    
else
    
    babsPath = varargin{1};
    success = babsSegmentation(cerrPath,fullSessionPath,babsPath,AIresultCERRPath);
    
    % Export the RTSTRUCT file
    savePlancFlag = 0;
    if strcmpi(savePlanc,'yes')
        savePlancFlag = 1;
    end
    exportCERRtoDICOM_forBABS(origCerrPath,AIresultCERRPath,outputCERRPath,...
        outputDicomPath,dcmExportOptS,savePlancFlag)
    
end

% Remove session directory
rmdir(fullSessionPath, 's')

success = 0;

