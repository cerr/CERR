function exportGspsToRTstruct(sourceDir,destDir,protocolLabel)
% function exportGspsToRTstruct(sourceDir,destDir,protocolLabel)
%
% Function to convert GSPS DICOM contours to RTSTRUCT DICOM
%
% INPUTS:
% sourceDir: directory containing DICOM (images and GSPS)
% destDir: directory to export DICOM (images and RTSTRUCT)
% protocolLabel: protocol label. If missing, all annotations will be
% converted to DICOM RTSTRUCT
%
% LIMITATIONS:
% Currently only works for HFS patient positions
%
% APA, 9/14/2017

if ~exist('sourceDir','var')
    sourceDir = uigetdir('','Select Source Directory');     
end
if ~exist('destDir','var')
    destDir = uigetdir('','Select Destination Directory');
end
if ~exist('protocolLabel','var')
    protocolLabel = input('Enter Protocol Number: \n','s');
end

%% ------ Import DICOM with GSPS
hWaitbar = waitbar(0,'Scanning Directory Please wait...');
[~,dirsInCurDir] = rdir(sourceDir);
dirsInCurDir(end+1).fullpath = sourceDir;
dcmdirS = []; 
patientNum = 1;

for i = 1:length(dirsInCurDir)
    %     patient = scandir_mldcm(fullfile(path, dirs(i).name), hWaitbar, i);
    patient = scandir_mldcm(dirsInCurDir(i).fullpath, hWaitbar, i);
    if ~isempty(patient)
        for j = 1:length(patient.PATIENT)
            dcmdirS.(['patient_' num2str(patientNum)]) = patient.PATIENT(j);
            patientNum = patientNum + 1;
        end
    end
end
close(hWaitbar)

patNameC = fieldnames(dcmdirS);
combinedDcmdirS = struct('STUDY',dcmdirS.(patNameC{1}).STUDY,'info',dcmdirS.(patNameC{1}).info);
for i = 2:length(patNameC)
    for j = 1:length(dcmdirS.(patNameC{i}).STUDY.SERIES)
        combinedDcmdirS.STUDY.SERIES(end+1) = dcmdirS.(patNameC{i}).STUDY.SERIES(j);
    end
end
% Pass the java dicom structures to function to create CERR plan
mergeScansFlag = 'No';
planC = dcmdir2planC(combinedDcmdirS,mergeScansFlag);

%% ------ Convert GSPS to CERR Structure
% Find gsps objects that match protocol
indexS = planC{end};
if ~isempty(protocolLabel)
    indMatchV = strcmpi({planC{indexS.GSPS}.presentLabel},protocolLabel);
else
    indMatchV = 1:length(planC{indexS.GSPS});
end
gspsNumsV = find(indMatchV);
scanNum = 1;
planC = gspsToStruct(scanNum,gspsNumsV,planC);


%% ------ Export DICOM with RTSTRUCT
export_planC_to_DICOM(planC, destDir);

disp(['Finished exporting RTSTRUCT to ',destDir])

