function batch_export_to_DICOM(varargin)
%function batch_export_to_DICOM(sourceCERRDir,destDICOMDir)
%
%This function exports DICOM for CERR plans from sourceCERRDir to destDICOMDir
%
%APA, 08/27/2012
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

persistent convertedC planNameC
if isempty(varargin)
    %init_ML_DICOM
    convertedC = {'Source Directory:'};
    planNameC = {'Converted Plan Name:'};
    researchNumberC = {'MedPhys Research Number:'};
    sourceCERRDir = uigetdir(cd, 'Select Source directory');
    if isnumeric(sourceCERRDir)
        return;
    end
    destDICOMDir = uigetdir(cd, 'Select Destination directory');
    if isnumeric(destDICOMDir)
        return;
    end
else
    convertedC = {'Source Directory:'};
    planNameC = {'Converted Plan Name:'};
    researchNumberC = {'MedPhys Research Number:'};
    sourceCERRDir = varargin{1};
    destDICOMDir = varargin{2};
end

init_ML_DICOM

if ispc
    slashType = '\';
else
    slashType = '/';
end
if strcmpi(sourceCERRDir(end),slashType)
    sourceCERRDir(end) = [];
end
allDirS = dir(sourceCERRDir);
for dirNum = 1:length(allDirS)

    [pathStr,nameStr,extStr] = fileparts(allDirS(dirNum).name);
    %[pathStr,nameStr,extStr2] = fileparts(nameStr);
    if ~allDirS(dirNum).isdir && (strcmpi(extStr,'.bz2') || strcmpi(extStr,'.mat') || strcmpi(extStr,'.zip')) && ~ismember(sourceCERRDir,convertedC)
        
        if ~strcmpi(sourceCERRDir(end),slashType)
            sourceCERRDir = [sourceCERRDir,slashType];
        end
        
        fileName = fullfile(sourceCERRDir, allDirS(dirNum).name);
        
        try
            
            disp(['Converting ',fileName,' ...'])
            planC = loadPlanC(fileName, tempdir);
            
            planC = updatePlanFields(planC);
            
            % Quality Assure
            planC = quality_assure_planC(fileName, planC);
            
            % Generate Folder Name
            [jnk,folderName] = fileparts(fileName);
            fullFolderPath = fullfile(destDICOMDir,folderName);
            
            if ~exist(fullFolderPath,'dir')
                mkdir(fullFolderPath)
            end
            
            % Export to DICOM
            export_planC_to_DICOM(planC, fullFolderPath)
            
            clear planC
            convertedC{end+1} = allDirS(dirNum).name;
            planNameC{end+1} = fileName;
        catch
            convertedC{end+1} = allDirS(dirNum).name;
            planNameC{end+1} = 'NOT CONVERTED';
            disp(['NOT CONVERTED ',allDirS(dirNum).name,' ...'])
        end
        
    elseif allDirS(dirNum).isdir && ~strcmp(allDirS(dirNum).name,'.') && ~strcmp(allDirS(dirNum).name,'..')
        batch_export_to_DICOM(fullfile(sourceCERRDir,allDirS(dirNum).name),destDICOMDir)
    end
end
if isempty(varargin)
    for i=1:length(convertedC)
        xlswrite(fullfile(destDICOMDir,'batch_convert_results.xls'),{convertedC{i}},'Sheet1',['A',num2str(i)])
        xlswrite(fullfile(destDICOMDir,'batch_convert_results.xls'),{planNameC{i}},'Sheet1',['B',num2str(i)])
    end
end



