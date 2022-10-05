function planC = dicomDirToPlanC(dirPath,optS,mergeScansFlag)
% function planC = dicomDirToPlanC(dirPath,optS,mergeScansFlag)
%
% APA, 9/23/2021

% Read options if not passed
if exist('optS','var') && ~isempty(optS) && isstruct(optS) % optS is filename of json file
    %passed optS is already a structure. Use as is.
elseif exist('optS','var') && ~isempty(optS) && ischar(optS)  % optS is filename of json file
    optS = opts4Exe(optS);
else  % default CERROptions.json from CERR distribution
    pathStr = getCERRPath;
    optName = [pathStr 'CERROptions.json'];
    optS = opts4Exe(optName);
end

if ~exist('mergeScansFlag','var')
    mergeScansFlag = 'No';
end

planC = {};
dcmdirS = [];
patientNum = 1;
recursiveFlag = true;
excludePixelDataFlag = true;
patient = scandir_mldcm(dirPath, excludePixelDataFlag, recursiveFlag);
if ~isempty(patient)
    for j = 1:length(patient.PATIENT)
        dcmdirS.(['patient_' num2str(patientNum)]) = patient.PATIENT(j);
        patientNum = patientNum + 1;
    end
end

if isempty(dcmdirS)
    return;
end

patNameC = fieldnames(dcmdirS);

combinedDcmdirS = struct('STUDY',dcmdirS.(patNameC{1}).STUDY,'info',dcmdirS.(patNameC{1}).info);
count = 0;
newCombinedDcmdirS = struct('STUDY','');
for studyCount = 1:length(combinedDcmdirS.STUDY)
    for seriesCount = 1:length(combinedDcmdirS.STUDY(studyCount).SERIES)
        count = count + 1;
        newCombinedDcmdirS.STUDY.SERIES(count) = combinedDcmdirS.STUDY(studyCount).SERIES(seriesCount);
    end
end
combinedDcmdirS = newCombinedDcmdirS;
for i = 2:length(patNameC)
    for  k = 1:length(dcmdirS.(patNameC{i}).STUDY)
        for j = 1:length(dcmdirS.(patNameC{i}).STUDY(k).SERIES)
            combinedDcmdirS.STUDY.SERIES(end+1) = dcmdirS.(patNameC{i}).STUDY(k).SERIES(j);
        end
    end
end
% Pass the java dicom structures to function to create CERR plan
planC = dcmdir2planC(combinedDcmdirS,mergeScansFlag,optS);
