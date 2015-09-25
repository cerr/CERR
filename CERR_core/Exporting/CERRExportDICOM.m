function CERRExportDICOM(varargin)
% Script that runs DICOM Export in CERR.
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
    initFlag = init_ML_DICOM;
    pathStr = getCERRPath;
    optName = [pathStr 'CERROptions.m'];    
    stateS.optS = opts4Exe(optName);
else
    initFlag = 1;
end

if ~initFlag
    CERRStatusString('Exiting CERR Export...');
    return;
end

% Check if source and destination have been specified
if ~isempty(varargin)
   fileToExport = varargin{1};
   destDir = varargin{2};
   batch_flag = 1;
   
else
    batch_flag = 0;
    
end

if ~batch_flag
    % select the CERR plan
    [filename,pathname]= uigetfile('*.mat;*.mat.bz2;*.mat.zip;*.mat.tar;*.mat.bz2.tar;*.mat.zip.tar','Select CERR plan to Export');
    if ~filename
        CERRStatusString('Exiting CERR Export...');
        return;
    end
    
    fileToExport = fullfile(pathname,filename);    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% added support for bz2, tar and zip files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[pathstr, name, ext] = fileparts(fileToExport);

% %untar if it is a .tar file
% tarFile = 0;
% if strcmpi(ext, '.tar')
%     untar(fileToExport,pathstr)
%     fileToUnzip = fullfile(pathstr, name);
%     file = fileToUnzip;
%     [pathstr, name, ext] = fileparts(fullfile(pathstr, name));
%     tarFile = 1;
% end

%Get temporary directory to extract uncompress
optS = stateS.optS;
if isempty(optS.tmpDecompressDir)
    tmpExtractDir = tempdir;
elseif isdir(optS.tmpDecompressDir)
    tmpExtractDir = optS.tmpDecompressDir;
elseif ~isdir(optS.tmpDecompressDir)
    error('Please specify a valid directory within CERROptions.m for optS.tmpDecompressDir')
end

if strcmpi(ext, '.bz2')
    zipFile = 1;
    CERRStatusString(['Decompressing ' name ext '...']);
    outstr = gnuCERRCompression(fileToExport, 'uncompress',tmpExtractDir);
    if ispc
        loadfile = fullfile(tmpExtractDir, name);
    else
        loadfile = fullfile(pathstr, name);
    end    
    [pathstr, name, ext] = fileparts(fullfile(pathstr, name));
elseif strcmpi(ext, '.zip')
    zipFile = 1;
    unzip(fileToExport,pathstr)
    if ispc
        unzip(file,tmpExtractDir)
        loadfile = fullfile(tmpExtractDir, name);
    else
        unzip(file,pathstr)
        loadfile = fullfile(pathstr, name);
    end
    [pathstr, name, ext] = fileparts(fullfile(pathstr, name));
else
    zipFile = 0;
    loadfile = fileToExport;
end

CERRStatusString(['Loading ' name ext '...']);

planC = load(loadfile,'planC');
try
    if zipFile
        delete(loadfile);
    end
    if tarFile
        delete(fileToUnzip);
    end
catch
end

planC = planC.planC;

planC = updatePlanFields(planC);

indexS = planC{end};

if ~isfield(indexS,'IVH')
    planC = updatePlanIVH(planC);
    indexS = planC{end}; % Reset indexS structure
end

if ~isfield(planC{indexS.scan}(1),'scanUID')| ((length(planC{indexS.structureArray})>0) & (~isfield(planC{indexS.structureArray}(1),'structureSetUID')))
    planC = guessPlanUID(planC);
end

if ~batch_flag

    %destDir = uigetdir('C:/','Select the Destination Folder');
    destDir = uigetdir(cd,'Select the Destination Folder');
    
    if ~destDir
        CERRStatusString('Exiting CERR Export...');
        return;
    end
    
end


optS = CERROptions;

%Check color assignment for displaying structures
[assocScanV,relStrNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);

for scanNum = 1:length(planC{indexS.scan})
    scanIndV = find(assocScanV==scanNum);

    for i = 1:length(scanIndV)
        strNum = scanIndV(i);
        colorNum = relStrNumV(strNum);
    
        if isempty(planC{indexS.structures}(strNum).structureColor)
            color = optS.colorOrder( mod(colorNum-1, size(optS.colorOrder,1))+1,:);
            planC{indexS.structures}(strNum).structureColor = color;
        end

    end
end

planC = checkForOldPlan(planC);

export_planC_to_DICOM(planC, destDir);