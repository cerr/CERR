function insertDCMStruct(planC,dcmFileName)
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

dataS = populate_planC_field('structures', dcmdirS.PATIENT);

% Check scan to associate the strucutres
scanUIDc = {planC{indexS.scan}.scanUID};
numScans = length(planC{indexS.scan});
scanTypesC = {};
for i = 1 : numScans
    scanTypesC{i} = [num2str(i) '.  ' planC{indexS.scan}(i).scanType];
end

% Return if not a valid RTStruct file
if isempty(dataS)
    CERRStatusString('File not valid.')
    return
end

if ~ismember(dataS(1).assocScanUID,scanUIDc)
    scanInd = listdlg('PromptString','Select Scan to associate structures',...
        'SelectionMode','single',...
        'ListString',scanTypesC);
    if ~isempty(scanInd)
        [dataS.assocScanUID] = deal(scanUIDc{scanInd});
    else
        return
    end
end
numStructs = length(planC{indexS.structures});
for i=1:length(dataS)    
    dataS(i) = sortStructures(dataS(i)); 
    colorNum = numStructs + i;
    if isempty(dataS(i).structureColor)
        color = stateS.optS.colorOrder( mod(colorNum-1, size(stateS.optS.colorOrder,1))+1,:);
        dataS(i).structureColor = color;
    end
end
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
