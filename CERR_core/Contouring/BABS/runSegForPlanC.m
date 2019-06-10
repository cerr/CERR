function planC = runSegForPlanC(planC,sessionPath,algorithm,varargin)
% function planC = runSegForPlanC(planC,sessionPath,algorithm,varargin)
%
% This function serves as a wrapper for different types of segmentations.
%
% INPUT: 
% planC - CERR's planC object.
% sessionPath - path to write temporary segmentation metadata.
% algorithm - string which specifies segmentation algorith
% varargin - additional algorithm-specific inputs
%
% Following directories are created within the session directory:
% --- ctCERR: contains CERR file from planC.
% --- segmentedOrigCERR: CERR file with resulting segmentation fused with 
% original CERR file.
% --- segResultCERR: CERR file with segmentation. Note that CERR file can
% be cropped based on initial segmentation.
%
% EXAMPLE: to run segmentation, load a plan in CERR followed by:
% global planC
% sessionPath = '/path/to/session/dir';
% algorithm = 'CT_Heart_DeepLab';
% success = runSegClinic(inputDicomPath,outputDicomPath,sessionPath,algorithm);
%
% APA, 06/10/2019


% Create session directory to write segmentation metadata

global stateS

indexS = planC{end};

% Use series uid in temporary folder name
if isfield(planC{indexS.scan}.scanInfo(1),'DICOMHeaders')
    folderNam = planC{indexS.scan}.scanInfo(1).DICOMHeaders.SeriesInstanceUID;
else
    folderNam = dicomuid;
end

dateTimeV = clock;
randNum = 1000.*rand;
sessionDir = ['session',folderNam,num2str(dateTimeV(4)), num2str(dateTimeV(5)),...
    num2str(dateTimeV(6)), num2str(randNum)];

fullSessionPath = fullfile(sessionPath,sessionDir);

% Create directories to write CERR files
mkdir(fullSessionPath)
cerrPath = fullfile(fullSessionPath,'ctCERR');
mkdir(cerrPath)
outputCERRPath = fullfile(fullSessionPath,'segmentedOrigCERR');
mkdir(outputCERRPath)
segResultCERRRPath = fullfile(fullSessionPath,'segResultCERR');
mkdir(segResultCERRRPath)

% Write planC to CERR .mat file
cerrFileName = fullfile(cerrPath,'cerrFile.mat');
save_planC(planC,[],'passed',cerrFileName);

switch algorithm
    
    case 'BABS'        
        
        babsPath = varargin{1};
        success = babsSegmentation(cerrPath,fullSessionPath,babsPath,segResultCERRRPath);
        
        
 
    otherwise 
        containerPath = varargin{1};                        
        success = segmentationWrapper(cerrPath,segResultCERRRPath,fullSessionPath,containerPath,algorithm);
        
end

% Export the RTSTRUCT file
%exportCERRtoDICOM(cerrPath,segResultCERRRPath,outputCERRPath,outputDicomPath)

% Read segmentation from segResultCERRRPath to display in viewer
segFileName = fullfile(segResultCERRRPath,'cerrFile.mat');
planD = loadPlanC(segFileName);
indexSD = planD{end};
scanIndV = 1;
doseIndV = [];
numSegStr = length(planD{indexSD.structures});
numOrigStr = length(planC{indexS.structures});
structIndV = 1:numSegStr;
planC = planMerge(planC, planD, scanIndV, doseIndV, structIndV, '');
for iStr = 1:numSegStr
    planC = copyStrToScan(numOrigStr+iStr,1,planC);
end
planC = deleteScan(planC, 2);
for structNum = numOrigStr:-1:1
    planC = deleteStructure(planC, structNum);
end

% Remove session directory
rmdir(fullSessionPath, 's')

% refresh the viewer
if ~isempty(stateS) && stateS.handle.CERRSliceViewer
    stateS.structsChanged = 1;
    CERRRefresh
end



