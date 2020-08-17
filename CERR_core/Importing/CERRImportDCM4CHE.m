function CERRImportDCM4CHE()
% CERRImportDCM4CHE
% imports the DICOM data into CERR plan format. This function is based on
% the Java code dcm4che.
% written DK, WY
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
%
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
%
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
%
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
%
% CERR is distributed under the terms of the Lesser GNU Public License.
%
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.


global stateS
if ~isfield(stateS,'initDicomFlag')
    flag = init_ML_DICOM;
    if ~flag
        return;
    end
elseif isfield(stateS,'initDicomFlag') && ~stateS.initDicomFlag
    return;
end

% Get the path of the directory to be selected for import.
dirPath = uigetdir(pwd','Select the DICOM directory to scan:');
pause(0.1);

if ~dirPath
    disp('DICOM import aborted');
    return
end

tic;

% Read options file
pathStr = getCERRPath;
optName = [pathStr 'CERROptions.json'];
optS = opts4Exe(optName);

hWaitbar = waitbar(0,'Scanning Directory Please wait...');
CERRStatusString('Scanning DICOM directory');

dcmdirS = [];
patientNum = 1;
excludePixelDataFlag = true;

patient = scandir_mldcm(dirPath, hWaitbar, 1, excludePixelDataFlag);
if ~isempty(patient)
    for j = 1:length(patient.PATIENT)
        dcmdirS.(['patient_' num2str(patientNum)]) = patient.PATIENT(j);
        patientNum = patientNum + 1;
    end
end
if isfield(optS,'importDICOMsubDirs') && strcmpi(optS.importDICOMsubDirs,'yes') % && ~isempty(dirsInCurDir)
    
    [filesInCurDir,dirsInCurDir] = rdir(dirPath);
    
    for i = 1:length(dirsInCurDir)
        %     patient = scandir_mldcm(fullfile(dirPath, dirs(i).name), hWaitbar, i);
        patient = scandir_mldcm(dirsInCurDir(i).fullpath, hWaitbar, i, excludePixelDataFlag);
        if ~isempty(patient)
            for j = 1:length(patient.PATIENT)
                dcmdirS.(['patient_' num2str(patientNum)]) = patient.PATIENT(j);
                patientNum = patientNum + 1;
            end
        end
    end
end

if isempty(dcmdirS)
    close(hWaitbar);
    msgbox('There is no dicom data!','Application Info','warn');
    return;
end

close(hWaitbar);

selected = showDCMInfo(dcmdirS);
patNameC = fieldnames(dcmdirS);
if isempty(selected)
    return
elseif strcmpi(selected,'all')
    combinedDcmdirS = struct('STUDY',dcmdirS.(patNameC{1}).STUDY,'info',dcmdirS.(patNameC{1}).info);
    count = 0;
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
    planC = dcmdir2planC(combinedDcmdirS);
else
    % Pass the java dicom structures to function to create CERR plan
    planC = dcmdir2planC(dcmdirS.(selected)); %wy
end

indexS = planC{end};

%-------------Store CERR version number---------------%
[version, date] = CERRCurrentVersion;
planC{indexS.header}.CERRImportVersion = [version, ', ', date];

toc;
pause(0.05)
save_planC(planC,planC{indexS.CERROptions});

