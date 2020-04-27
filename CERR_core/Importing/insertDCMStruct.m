function planC = insertDCMStruct(planC,dcmFileName)
%
%Insert structures from dcm file into the currently open planC.
%
% 06/05/2015
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
%
% AI 2/13/20 Updated to account for pt orientation

global stateS

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

if ~exist('dcmFileName','var')
    [fileName, dirName] = uigetfile('*.dcm','Pick Structure file');
    dcmFileName = fullfile(dirName,fileName);
end

[dcmObj, isDcm] = scanfile_mldcm(dcmFileName);
dcmdirS = [];
if isDcm
    dcmdirS = dcmdir_add(dcmFileName, dcmObj, dcmdirS);
    dcmObj.clear;
else
    error('Invalid DICOM data')
end

% Read CERROptions.json
pathStr = getCERRPath;
optName = [pathStr 'CERROptions.json'];
optS = opts4Exe(optName);

scanOriS = planC{indexS.scan};
for scanNum = 1:length(scanOriS)
    imageOrientationPatient = scanOriS(scanNum).scanInfo(1).imageOrientationPatient;
    scanOriS(scanNum).imageOrientationPatient = imageOrientationPatient;
end

dataS = populate_planC_field('structures', dcmdirS.PATIENT, optS, scanOriS);

% Tolerance to determine oblique scan (think about passing it as a
% parameter in future)
numScans = length(planC{indexS.scan});
obliqTol = 1e-3;
isObliqScanV = zeros(1,numScans);

% Check scan to associate the strucutres
scanUIDc = {planC{indexS.scan}.scanUID};
scanTypesC = {};
for i = 1 : numScans
    scanTypesC{i} = [num2str(i) '.  ' planC{indexS.scan}(i).scanType];
    
    ImageOrientationPatientV = planC{indexS.scan}(i).scanInfo(1).imageOrientationPatient;
    
    % Check for obliqueness
    %     if ~isempty(ImageOrientationPatientV) && max(abs((abs(ImageOrientationPatientV) - [1 0 0 0 1 0]'))) <= obliqTol
    %         isObliqScanV(i) = 0;
    %     end
    if ~isempty(ImageOrientationPatientV)
        if max(abs((ImageOrientationPatientV(:) - [1 0 0 0 1 0]'))) < 1e-3
            isObliqScanV(i) = 0;
        elseif max(abs((ImageOrientationPatientV(:) - [-1 0 0 0 1 0]'))) < 1e-3
            isObliqScanV(i) = 0;
        elseif max(abs((ImageOrientationPatientV(:) - [-1 0 0 0 -1 0]'))) < 1e-3
            isObliqScanV(i) = 0;
        elseif max(abs((ImageOrientationPatientV(:) - [1 0 0 0 -1 0]'))) < 1e-3
            isObliqScanV(i) = 0;
        else
            isObliqScanV(i) = 1;
        end
    else
        if ~isempty(planC{indexS.scan}(i).scanInfo(1).imageOrientationPatient)
            ImageOrientationPatientV = planC{indexS.scan}(i).scanInfo(1).imageOrientationPatient;
        else
            ImageOrientationPatientV = [];
            isObliqScanV(i) = 1;
        end
        
    end
    
end

% Return if not a valid RTStruct file
if isempty(dataS)
    CERRStatusString('File not valid.')
    return
end

if ~ismember(dataS(1).assocScanUID,scanUIDc)
    if ~exist('dcmFileName','var')
        scanInd = listdlg('PromptString','Select Scan to associate structures',...
            'SelectionMode','single',...
            'ListString',scanTypesC);
    else
        scanInd = 1;
    end
    if ~isempty(scanInd)
        [dataS.assocScanUID] = deal(scanUIDc{scanInd});
    else
        return
    end
end
numStructs = length(planC{indexS.structures});
for i=1:length(dataS)
    dataS(i) = sortStructures(dataS(i),isObliqScanV,planC);
    colorNum = numStructs + i;
    if isempty(dataS(i).structureColor)
        color = stateS.optS.colorOrder( mod(colorNum-1, size(stateS.optS.colorOrder,1))+1,:);
        dataS(i).structureColor = color;
    end
end
%Find any structures in dataS not already in planC.
toDeleteV = [];
for i=length(dataS):-1:1
    %     newStructName = temp_planC{temp_planC{end}.structures}(i).structureName;
    newStructData = dataS(i).contour;
    for j=1:length(planC{planC{end}.structures})
        oldStructName = planC{planC{end}.structures}(j).structureName;
        oldStructData = planC{planC{end}.structures}(j).contour;
        if isequal(newStructData, oldStructData)
            disp(['Structure "',oldStructName,'" already exists. Duplicate structure will not be inserted.']);
            toDeleteV = [toDeleteV, i];
            break;
        end
    end
end
dataS(toDeleteV) = [];
if ~isempty(planC{indexS.structures})
    for strNum = 1:length(dataS)
        planC{indexS.structures} = dissimilarInsert(planC{indexS.structures},dataS(strNum),length(planC{indexS.structures})+1);
    end
else
    planC{indexS.structures} = dataS;
end

editStructNumV = (numStructs+1):length(planC{indexS.structures});
planC = getRasterSegs(planC,editStructNumV);
%planC = setUniformizedData(planC);
for strNum = editStructNumV
    planC = updateStructureMatrices(planC, strNum);
end

if isfield(stateS, 'CERRFile')
    stateS.structsChanged = 1;
    CERRRefresh
end

CERRStatusString('Done inserting structures.')
