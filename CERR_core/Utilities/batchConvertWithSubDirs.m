function batchConvertWithSubDirs(varargin)
%function batchConvertWithSubDirs(sourceDir,destinationDir,zipFlag,mergeScansFlag,singleCerrFileFlag)
%
%Type "init_ML_DICOM; batchConvertWithSubDirs" (without quotes) in Command window to run batch conversion. User will be
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
% singleCerrFileFlag = 'No';
% batchConvertWithSubDirs(sourceDir,destinationDir,zipFlag,mergeScansFlag,singleCerrFileFlag)

if isempty(ver('OCTAVE'))
    feature accel off
end

% Read options file
pathStr = getCERRPath;
optName = [pathStr 'CERROptions.json'];
optS = opts4Exe(optName);

%persistent convertedC planNameC
if isempty(varargin)
    %init_ML_DICOM
    %convertedC = {'Source Directory:'};
    %planNameC = {'Converted Plan Name:'};
    sourceDir = uigetdir(cd, 'Select Source directory');
    if isnumeric(sourceDir)
        return;
    end
    destinationDir = uigetdir(cd, 'Select Destination directory');
    if isnumeric(destinationDir)
        return;
    end
    zipFlag = questdlg('Do you want to bz2 zip output CERR files?', 'bz2 Zip files?', 'Yes','No','No');
    mergeScansFlag = 'no';
    singleCerrFileFlag = questdlg('Do you want to import all directories to single CERR file?', 'Single CERR file?', 'Yes','No','No');
else
    %convertedC = {'Source Directory:'};
    %planNameC = {'Converted Plan Name:'};
    sourceDir = varargin{1};
    destinationDir = varargin{2};
    zipFlag = varargin{3};
    mergeScansFlag = varargin{4};
    singleCerrFileFlag = 'no';
    if length(varargin) > 4
        singleCerrFileFlag = varargin{5};
    end
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
namC = {allDirS.name};
if strcmpi(singleCerrFileFlag,'yes')
    indCurrentDir = ismember(namC,'.');
    allDirS = allDirS(indCurrentDir);
else
    indRemoveV = ismember(namC,{'.','..'});
    allDirS(indRemoveV) = [];
end

convertedC = cell(length(allDirS),1);
planNameC = cell(length(allDirS),1);
for dirNum = 1:length(allDirS)
    [pathStr,nameStr,extStr] = fileparts(allDirS(dirNum).name);
    %[pathStr,nameStr,extStr] = fileparts(allDirS(dirNum).name);
    
    %if allDirS(dirNum).isdir && ~strcmpi(extStr,'.zip') && ~ismember(sourceDir,convertedC)
    
    disp(['Importing ',sourceDir,' ...'])
    try
        
        %hWaitbar = waitbar(0,'Scanning Directory Please wait...');
        CERRStatusString('Scanning DICOM directory');
                      
        dirPath = fullfile(sourceDir,allDirS(dirNum).name);    
        
        %% Import directory to planC
        planC = dicomDirToPlanC(dirPath,optS,mergeScansFlag);
        

        %% Save planC to file
        
        [sourcePath,sourceDirName] = fileparts(dirPath);
        if isempty(sourceDirName)
            [~,sourceDirName] = fileparts(sourcePath);
        end
        
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
        %clear planC
        %convertedC{end+1} = sourceDir;
        %planNameC{end+1} = [sourceDirName,'.mat.bz2'];
        convertedC{dirNum} = sourceDir;
        planNameC{dirNum} = [sourceDirName,'.mat.bz2'];
        
    catch
        convertedC{dirNum} = sourceDir;
        planNameC{dirNum} = 'NOT CONVERTED';
        disp(['NOT CONVERTED ',sourceDir,' ...'])
    end
    %elseif allDirS(dirNum).isdir && ~strcmp(allDirS(dirNum).name,'.') && ~strcmp(allDirS(dirNum).name,'..')
    %    batchConvert(fullfile(sourceDir,allDirS(dirNum).name),destinationDir, zipFlag, mergeScansFlag)
    %end
end
if isempty(varargin)
    for i=1:length(convertedC)
        xlswrite(fullfile(destinationDir,'batch_convert_results.xls'),{convertedC{i}},'Sheet1',['A',num2str(i)])
        xlswrite(fullfile(destinationDir,'batch_convert_results.xls'),{planNameC{i}},'Sheet1',['B',num2str(i)])
    end
end
end
