function insertDCMDose(planC,dcmFileName)
%
%Insert dose from dcm file into the currently open planC.
%
% 11/07/2013
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
    [fileName, dirName] = uigetfile('*.dcm','Pick Dose file');
    dcmFileName = fullfile(dirName,fileName);
end

dcmInitFlag = init_ML_DICOM;
[dcmObj, isDcm] = scanfile_mldcm(dcmFileName);
dcmdirS = [];
if isDcm
    dcmdirS = dcmdir_add(dcmFileName, dcmObj, dcmdirS);
    dcmObj.clear;
else
    error('Invalid DICOM data')
end

% Read options file
pathStr = getCERRPath;
optName = [pathStr 'CERROptions.json'];
optS = opts4Exe(optName);

dataS = populate_planC_field('dose', dcmdirS.PATIENT,optS);

if ~isempty(planC{indexS.dose})
    planC{indexS.dose} = dissimilarInsert(planC{indexS.dose},dataS,length(planC{indexS.dose})+1);
else
    planC{indexS.dose} = dataS;
end

%Check dose-grid
doseNum = length(planC{indexS.dose});
for doseNum = 1:length(planC{indexS.dose})
    if planC{indexS.dose}(doseNum).zValues(2) - planC{indexS.dose}(doseNum).zValues(1) < 0
        planC{indexS.dose}(doseNum).zValues = flipud(planC{indexS.dose}(doseNum).zValues);
        planC{indexS.dose}(doseNum).doseArray = flipdim(planC{indexS.dose}(doseNum).doseArray,3);
    end
end

if isfield(stateS, 'CERRFile')
    stateS.doseSetChanged = 1;
    stateS.doseDisplayChanged = 1;
    stateS.doseSet = length(planC{indexS.dose});
    CERRRefresh
end

CERRStatusString('Done inserting dose.')
