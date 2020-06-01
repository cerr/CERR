function batchConvert(varargin)
%function batchConvert(sourceDir,destinationDir,zipFlag,mergeScansFlag)
%
%Type "init_ML_DICOM; batchConvert" (without quotes) in Command window to run batch conversion. User will be
%prompted to select source and destination directories. This function converts DICOM and RTOG files 
%under sourceDir and subdirectories to CERR format and places them in destinationDir.
%
%APA, 01/22/2009
% AI, 05/26/17 Added mergeScansFlag
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


% Example-run
% sourceDir = 'J:\bioruser\apte\batch code';
% destinationDir = 'J:\bioruser\apte\batch code\OUT';
% zipFlag = 'No';
% mergeScansFlag = 'No';
% batchConvert(sourceDir,destinationDir,zipFlag,mergeScansFlag)

feature accel off

persistent convertedC planNameC
if isempty(varargin)    
    %init_ML_DICOM
    convertedC = {'Source Directory:'};
    planNameC = {'Converted Plan Name:'};
    sourceDir = uigetdir(cd, 'Select Source directory');
    if isnumeric(sourceDir)
        return;
    end
    destinationDir = uigetdir(cd, 'Select Destination directory');
    if isnumeric(destinationDir)        
        return;
    end
    zipFlag = questdlg('Do you want to bz2 zip output CERR files?', 'bz2 Zip files?', 'Yes','No','No');
    mergeScansFlag = [];
else    
    convertedC = {'Source Directory:'};
    planNameC = {'Converted Plan Name:'};    
    sourceDir = varargin{1};
    destinationDir = varargin{2};
    zipFlag = varargin{3};
    mergeScansFlag = varargin{4};
end

if ispc
    slashType = '\';
else
    slashType = '/';
end
if strcmpi(sourceDir(end),slashType)
    sourceDir(end) = [];
end
slashIndex = strfind(sourceDir,slashType);
allDirS = dir(sourceDir);

for dirNum = 1:length(allDirS)
    [pathStr,nameStr,extStr] = fileparts(allDirS(dirNum).name);
    if ~allDirS(dirNum).isdir && ~strcmpi(extStr,'.zip') && ~ismember(sourceDir,convertedC)
 
        if isrtog(fullfile(sourceDir,allDirS(dirNum).name))
            if ~strcmpi(sourceDir(end),slashType)
                sourceDir_rtog = [sourceDir,slashType];
            else
                sourceDir_rtog = sourceDir;
            end
            try
                disp(['Importing ',sourceDir_rtog,' ...'])
                planC = importRTOGDir(CERROptions,sourceDir_rtog, allDirS(dirNum).name);
                rtStartIndex = strfind(sourceDir,[slashType,'RT']);                
                if isempty(rtStartIndex)
                    rtStartIndex = slashIndex(end) + 1;
                    rtEndIndex = length(sourceDir);
                else
                    rtStartIndex = rtStartIndex(end);
                    rtEndIndex = slashIndex(find(slashIndex>rtStartIndex));
                    rtStartIndex = rtStartIndex+1;
                    if isempty(rtEndIndex)
                        rtEndIndex = length(sourceDir);
                    else
                        rtEndIndex = rtEndIndex - 1;
                    end
                end
                sourceDirName = sourceDir(rtStartIndex:rtEndIndex);
                %Check fr duplicate name of sourceDirName
                dirOut = dir(destinationDir);
                allOutNames = {dirOut.name};
                while any(strcmpi([sourceDirName,'.mat.bz2'],allOutNames))
                    sourceDirName = sourceDir(slashIndex(end-2)+1:end);
                    sourceDirName(strfind(sourceDirName,slashType)) = deal('_');
                end
                if strcmpi(zipFlag,'Yes')
                    save_planC(planC,[], 'passed', fullfile(destinationDir,[sourceDirName,'.mat.bz2']));
                else
                    save_planC(planC,[], 'passed', fullfile(destinationDir,[sourceDirName,'.mat']));
                end
                clear planC
                convertedC{end+1} = sourceDir;
                planNameC{end+1} = [sourceDirName,'.mat.bz2'];
            catch
                convertedC{end+1} = sourceDir;
                planNameC{end+1} = 'NOT CONVERTED';
                disp(['NOT CONVERTED ',sourceDir_rtog,' ...'])
            end
        elseif isdicom(fullfile(sourceDir,allDirS(dirNum).name))   
            disp(['Importing ',sourceDir,' ...'])
            try
                
%                 % temporary: for Mike Folkert data import of PET data only.
%                 dirUpNum = 2;
%                 modality = sourceDir(slashIndex(end-dirUpNum)+1:slashIndex(end-dirUpNum+1)-1);
%                 if strcmpi(modality,'mr')
%                     continue;
%                 end
%                 % temporary ends
                
                
                hWaitbar = waitbar(0,'Scanning Directory Please wait...');
                patient = scandir_mldcm(sourceDir, hWaitbar, 1);
                close(hWaitbar);
                for j = 1:length(patient.PATIENT)
                    dcmdirS.(['patient_' num2str(j)]) = patient.PATIENT(j);                    
                end
                patNameC = fieldnames(dcmdirS);
                selected = 'all';
                if strcmpi(selected,'all')
                    combinedDcmdirS = struct('STUDY',dcmdirS.(patNameC{1}).STUDY,'info',dcmdirS.(patNameC{1}).info);
                    for i = 2:length(patNameC)
                        for j = 1:length(dcmdirS.(patNameC{i}).STUDY.SERIES)
                            combinedDcmdirS.STUDY.SERIES(end+1) = dcmdirS.(patNameC{i}).STUDY.SERIES(j);
                        end
                    end
                    % Pass the java dicom structures to function to create CERR plan
                    planC = dcmdir2planC(combinedDcmdirS,mergeScansFlag); 
                else
                    planC = dcmdir2planC(patient.PATIENT);
                end       
%                 % For TopModule/Metropolis plans that are named as
%                 RT000000...
%                 rtStartIndex = strfind(sourceDir,[slashType,'RT']);                
%                 if isempty(rtStartIndex)
%                     rtStartIndex = slashIndex(end)+1;
%                     rtEndIndex = length(sourceDir);
%                 else
%                     rtStartIndex = rtStartIndex(end);
%                     rtEndIndex = slashIndex(find(slashIndex>rtStartIndex));
%                     rtStartIndex = rtStartIndex+1;
%                     if isempty(rtEndIndex)
%                         rtEndIndex = length(sourceDir);
%                     else
%                         rtEndIndex = rtEndIndex - 1;
%                     end
%                 end
%                 oneDirUp = sourceDir(slashIndex(end-1)+1:slashIndex(end)-1);
%                 twoDirUp = sourceDir(slashIndex(end-2)+1:slashIndex(end-2+1)-1);
%                 % For Metropolis with all plans per patient
%                 sourceDirName = [oneDirUp,'_',sourceDir(rtStartIndex:rtEndIndex)];
%                 % For Metropolis with one plan per patient
%                 sourceDirName = [oneDirUp];
%                 % For Irene PET/CT Histogram cauto-segmentation project
%                 dirUpNum = 2;
%                 twoDirUp = sourceDir(slashIndex(end-dirUpNum)+1:slashIndex(end-dirUpNum+1)-1);
%                 sourceDirName = [twoDirUp];
%                 indexS = planC{end};
%                 sourceDirName = [sourceDirName,'_',planC{indexS.scan}.scanInfo(1).imageType];
%                 % For Mike Folkert MR/PET data
%                 dirUpNum = 1;
%                 pre_post = sourceDir(slashIndex(end-dirUpNum)+1:slashIndex(end-dirUpNum+1)-1);
%                 dirUpNum = 2;
%                 modality = sourceDir(slashIndex(end-dirUpNum)+1:slashIndex(end-dirUpNum+1)-1);
%                 dirUpNum = 3;
%                 mrn = sourceDir(slashIndex(end-dirUpNum)+1:slashIndex(end-dirUpNum+1)-1);
%                 seriesName = sourceDir(slashIndex(end-0)+1:end);
%                 sourceDirName = fullfile(modality, pre_post, [mrn,'~',seriesName]);
%                 % General case
                % sourceDirName = sourceDir(rtStartIndex:rtEndIndex);
                [~,sourceDirName] = fileparts(sourceDir);
                %sourceDirName = strtok(sourceDirName,'_');
                %sourceDirName = [oneDirUp,'_',sourceDirName];
                
                %Check for duplicate name of sourceDirName
                dirOut = dir(destinationDir);
                allOutNames = {dirOut.name};
                indexSlash = 1;
                while indexSlash~=length(slashIndex) && any(strcmpi([sourceDirName,'.mat.bz2'],allOutNames))
                    sourceDirName = sourceDir(slashIndex(end-indexSlash)+1:end);
                    sourceDirName(strfind(sourceDirName,slashType)) = deal('_');
                    indexSlash = indexSlash + 1;
                end
                if any(strcmpi([sourceDirName,'.mat.bz2'],allOutNames))
                    sourceDirName = [sourceDir(rtStartIndex:rtEndIndex),'duplicate_',num2str(rand(1))];
                end                                
                if strcmpi(zipFlag,'Yes')
                    saved_fullFileName = fullfile(destinationDir,[sourceDirName,'.mat.bz2']);
                else
                    saved_fullFileName = fullfile(destinationDir,[sourceDirName,'.mat']);
                end                 
                if ~exist(fileparts(saved_fullFileName),'dir')
                    mkdir(fileparts(saved_fullFileName))
                end
                save_planC(planC,[], 'passed', saved_fullFileName);               
                clear planC
                convertedC{end+1} = sourceDir;
                planNameC{end+1} = [sourceDirName,'.mat.bz2'];
            catch
                convertedC{end+1} = sourceDir;
                planNameC{end+1} = 'NOT CONVERTED';
                disp(['NOT CONVERTED ',sourceDir,' ...'])
            end
        end
    elseif allDirS(dirNum).isdir && ~strcmp(allDirS(dirNum).name,'.') && ~strcmp(allDirS(dirNum).name,'..')
        batchConvert(fullfile(sourceDir,allDirS(dirNum).name),destinationDir, zipFlag, mergeScansFlag)
    end
end
if isempty(varargin)    
    for i=1:length(convertedC)
        xlswrite(fullfile(destinationDir,'batch_convert_results.xls'),{convertedC{i}},'Sheet1',['A',num2str(i)])
        xlswrite(fullfile(destinationDir,'batch_convert_results.xls'),{planNameC{i}},'Sheet1',['B',num2str(i)])
    end
end
end

function flag = isrtog(fileName)
flag = 0;
try 
    dicominfo(fileName);
    dcmflag = 1;
catch
    dcmflag = 0;
end
if ~dcmflag && ~isempty(strfind(fileName,'0000'))
    flag = 1;
end
end

function flag = isdicom(fileName)
flag = 0;
try 
    dicominfo(fileName);
    flag = 1;
catch
end
end

