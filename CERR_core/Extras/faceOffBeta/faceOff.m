function planC = faceOff(planC, scanNum, tmpDirPath, exportDICOMFlag, outputDICOMPath)

%% parse input and set up parameters, variables
if ~exist('exportDICOMFlag', 'var') && ~exist('outputDICOMPath','var')
        exportDICOMFlag = 0;
end

if exportDICOMFlag && (~exist('outputDICOMPath','var') || isempty(outputDICOMPath))
    outputDICOMPath = pwd;
end

if ~exist('tmpDirPath', 'var') || isempty(tmpDirPath)
    tmpDirPath = fullfile(getCERRPath,'ImageRegistration','tmpFiles');
end

%% ANTs setup
% optS = getCERROptions;
% if ~exist(optS.antspath_dir,'dir')
%     error(['ANTSPATH ' optS.antspath_dir ' not found on filesystem. Please review CERROptions.']);
% end
% antspath = fullfile(optS.antspath_dir,'bin');
% setenv('ANTSPATH', antspath);
% antsScriptPath = fullfile(optS.antspath_dir, 'Scripts');
% antsCERRScriptPath = fullfile(getCERRPath,'CERR_core', 'ImageRegistration', 'antsScripts');
% if isunix
%     setenv('PATH',[antspath ':' antsScriptPath ':' antsCERRScriptPath ':' getenv('PATH')]);
% else
%     setenv('PATH',[antspath ';' antsScriptPath ';' antsCERRScriptPath ';' getenv('PATH')]);
% end


%% register scan to template

% set affine transform 
inputCmdFile = fullfile(getCERRPath,'ImageRegistration','antsScripts','SyN_a.txt');
[templateImageFile, faceMaskImageFile] = loadTemplatePlanC;
[ ~, planC, ~] = register_scans(templatePlanC, 1, planC, scanNum, 'QuickSyn ANTs', 'ANTs', '', [], [], [], inputCmdFile);

%% inverse-warp the template face mask to scan space
indexS = planC{end};
deformS = planC{indexS.deform}(end);
inverseFlag = 1;
warp_structures(deformS, strCreationScanNum, movStructNumsV, planC, faceMaskImageFIle, inverseFlag);


%% export CERR to DICOM
disp('Exporting to DICOM format...');
if exportDicomFlag
    export_planC_to_DICOM(planC, outputDICOMPath, 0);
%     exportCERRtoDICOM(origCerrPath,allLabelNamesC,outputCERRPath,...
%         outputDicomPath,algorithm,savePlancFlag)
end


function [templateImageFile, faceMaskImageFile] = loadTemplatePlanC
    templateImageFile = fullfile(getCERRPath,'Extras','faceOffBeta','template0.nii.gz');
    faceMaskImageFile = fullfile(getCERRPath,'Extras','faceOffBeta','deface_template_40_M_GD_8.nii.gz');

