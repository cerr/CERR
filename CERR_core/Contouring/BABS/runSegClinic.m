function success = runSegClinic(inputDicomPath,outputDicomPath,...
    sessionPath,algorithm,savePlanc,varargin)
% function success = runSegClinic(inputDicomPath,outputDicomPath,...
%   sessionPath,algorithm,varargin)
%
% This function serves as a wrapper for different types of segmentations.
%
% INPUT: 
% inputDicomPath - path to input DICOM directory which needs to be segmented.
% outputDicomPath - path to write DICOM RTSTRUCT for resulting segmentation.
% sessionPath - path to write temporary segmentation metadata.
% algorithm - string which specifies segmentation algorith
% varargin - additional algorithm-specific inputs
%
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
% babsPath = '';
% savePlanc = 'Yes'; or 'No'
% success = runSegClinic(inputDicomPath,outputDicomPath,sessionPath,algorithm,babsPath);
%
%
% APA, 12/14/2018
% RKP, 9/11/19 Updates for compatibility with training pipeline


% Create session directory to write segmentation metadata

if inputDicomPath(end) == filesep
    [~,folderNam] = fileparts(inputDicomPath(1:end-1));
else
    [~,folderNam] = fileparts(inputDicomPath);
end

dateTimeV = clock;
randNum = 1000.*rand;
sessionDir = ['session',folderNam,num2str(dateTimeV(4)), num2str(dateTimeV(5)),...
    num2str(dateTimeV(6)), num2str(randNum)];

fullSessionPath = fullfile(sessionPath,sessionDir);

% Create directories to write CERR files
mkdir(fullSessionPath)
cerrPath = fullfile(fullSessionPath,'dataCERR');
mkdir(cerrPath)
outputCERRPath = fullfile(fullSessionPath,'segmentedOrigCERR');
mkdir(outputCERRPath)
segResultCERRPath = fullfile(fullSessionPath,'segResultCERR');
mkdir(segResultCERRPath)

% Import DICOM to CERR
importDICOM(inputDicomPath,cerrPath);

% algorithm
algorithmC = {};

[algorithmC{end+1},remStr] = strtok(algorithm,'^');
algorithmC{end} = char(algorithmC{end});
remStr = char(remStr);

while ~isempty(remStr) && ~isequal(remStr,"")
    [algorithmC{end+1},remStr] = strtok(remStr,'^');
    algorithmC{end} = char(algorithmC{end});
    remStr = char(remStr);
end

if iscell(algorithmC) || ~iscell(algorithmC) && ~strcmpi(algorithmC,'BABS')
    
        containerPath = varargin{1};      
        origCerrPath = cerrPath;
        for k=1:length(algorithmC)
            success = segmentationWrapper(cerrPath,segResultCERRPath,fullSessionPath,containerPath,algorithmC{k});   
            cerrPath = segResultCERRPath;
        end
    
else
    
        babsPath = varargin{1};
        success = babsSegmentation(cerrPath,fullSessionPath,babsPath,segResultCERRPath);
   
end

% Export the RTSTRUCT file
savePlancFlag = 0;
if strcmpi(savePlanc,'yes')
    savePlancFlag = 1;
end
exportCERRtoDICOM(origCerrPath,segResultCERRPath,outputCERRPath,...
    outputDicomPath,algorithm,savePlancFlag)

% Remove session directory
rmdir(fullSessionPath, 's')

success = 1;
