function batch_anonymize_CERR_plans(varargin)
%function batch_anonymize_CERR_plans(varargin)
%
%Type "function batch_anonymize_CERR_plans(varargin)" (without quotes) in Command window to run batch conversion. User will be
%prompted to select source and destination directories. This function anonymizes CERR plans under sourceDir and subdirectories
%and places them in destinationDir.
%
%APA, 10/05/2010
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
% batchConvert(sourceDir,destinationDir)

feature accel off

anonymize_file_name_flag = 1; % 1:anonymize file name with research number, 0: retain file name.
researchNumber = 1000; %naming will start with this number + 3.
replacementName = 'LungDoseResponse';

persistent convertedC planNameC
if isempty(varargin)
    %init_ML_DICOM
    convertedC = {'Source Directory:'};
    planNameC = {'Converted Plan Name:'};
    researchNumberC = {'MedPhys Research Number:'};
    sourceDir = uigetdir(cd, 'Select Source directory');
    if isnumeric(sourceDir)
        return;
    end
    destinationDir = uigetdir(cd, 'Select Destination directory');
    if isnumeric(destinationDir)
        return;
    end
else
    convertedC = {'Source Directory:'};
    planNameC = {'Converted Plan Name:'};
    researchNumberC = {'MedPhys Research Number:'};
    sourceDir = varargin{1};
    destinationDir = varargin{2};
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
    researchNumber = researchNumber + 1;
    [pathStr,nameStr,extStr] = fileparts(allDirS(dirNum).name);
    [pathStr,nameStr,extStr2] = fileparts(nameStr);
    if ~allDirS(dirNum).isdir && (strcmpi(extStr,'.bz2') || strcmpi(extStr,'.mat')) && ~ismember(sourceDir,convertedC)
        
        if ~strcmpi(sourceDir(end),slashType)
            sourceDir = [sourceDir,slashType];
        end
        
        fileName = fullfile(sourceDir, allDirS(dirNum).name);
        
        try
            
            disp(['Converting ',fileName,' ...'])
            planC = loadPlanC(fileName, tempdir);
            
            %Anonymize
            PHI = {'studyNumberOfOrigin','PatientName','caseNumber','archive','PatientID','scanDate','DICOMHeaders'};
            
            if ~isempty(replacementName)
                
                for i = 1 : length(PHI)
                    str = PHI{i};
                    %planC = anonymize(planC,str,replacementName);
                    planC = anonCERRplanC(planC);
                end
                
            end
            
            
            %Check for duplicate name of sourceDirName
            if anonymize_file_name_flag
                newFileName = [num2str(researchNumber),extStr];
            else
                sourceDirName = sourceDir;
                dirOut = dir(destinationDir);
                allOutNames = {dirOut.name};
                newFileName = allDirS(dirNum).name;
                indexSlash = 1;
                while indexSlash~=length(slashIndex) && any(strcmpi(newFileName, allOutNames))
                    newFileName = [sourceDirName,'_',newFileName];
                    sourceDirName = sourceDir(slashIndex(end-indexSlash)+1:end);
                    sourceDirName(strfind(sourceDirName,slashType)) = deal('_');
                    indexSlash = indexSlash + 1;
                end
                if any(strcmpi(newFileName,allOutNames))
                    newFileName = [newFileName,'duplicate_',num2str(rand(1)),extStr2,extStr];
                end
            end
            
            %save_planC(planC,[], 'passed', fullfile(destinationDir,[sourceDirName,'.mat.bz2']));
            save_planC(planC,[], 'passed', fullfile(destinationDir,newFileName));
            
            clear planC
            convertedC{end+1} = fileName;
            planNameC{end+1} = newFileName;
            researchNumberC{end+1} = num2str(researchNumber);
        catch
            convertedC{end+1} = fileName;
            planNameC{end+1} = 'NOT CONVERTED';
            researchNumberC{end+1} = num2str(researchNumber);
            disp(['NOT CONVERTED ',fileName,' ...'])
        end
        
    elseif allDirS(dirNum).isdir && ~strcmp(allDirS(dirNum).name,'.') && ~strcmp(allDirS(dirNum).name,'..')
        batch_anonymize_CERR_plans(fullfile(sourceDir,allDirS(dirNum).name),destinationDir)
    end    
end

% Save keys to Excel file
xlswrite(fullfile(destinationDir,'batch_convert_results.xls'),convertedC','Sheet1','A1')
xlswrite(fullfile(destinationDir,'batch_convert_results.xls'),planNameC','Sheet1','B1')
xlswrite(fullfile(destinationDir,'batch_convert_results.xls'),researchNumberC','Sheet1','C1')
