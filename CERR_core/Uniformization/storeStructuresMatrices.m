function planC = storeStructuresMatrices(planC, indicesM, structBitsM, indicesC, structBitsC, scanNum)
%"storeStructuresMatrices"
%   Either 1) modifies planC by adding another cell just before the index cell, or
%          2) uses the preallocated structureArray cell in planC.
%
%this new cell includes the index matrix and the bit matrix for the structures.
%
% 16 Aug 02, V H Clark
% 18 Feb 05, JRA, Added support for multiple scanSets.
% 12 Dec 05, DK, Check if scanNum exists during dicom import.
%Usage:
%   function planC = storeStructuresMatrices(planC, indicesM, structBitsM)
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

if ~exist('scanNum')
    scanNum = 1;
end

fieldExists = isfield(planC{end}, 'structureArray'); %this will be true for newer versions, false for old versions

if fieldExists %most common
    planC{planC{end}.structureArray}(scanNum).indicesArray = indicesM;
    planC{planC{end}.structureArray}(scanNum).bitsArray = structBitsM;
    planC{planC{end}.structureArray}(scanNum).assocScanUID = planC{planC{end}.scan}(scanNum).scanUID;
    planC{planC{end}.structureArray}(scanNum).structureSetUID = createUID('structureSet');
    try
        if isempty(stateS.structSet)
            stateS.structSet = getStructureSetAssociatedScan(stateS.scanSet,planC);
            stateS.structsChanged = 1;
        end
    end
else
    structIndex = length(planC);
    planC{end+1} = planC{end}; %moves the index to the end

    planC{structIndex}(scanNum) = struct('indicesArray', indicesC, 'bitsArray', structBitsC);
    %change index
    planC{end}.structureArray = structIndex;
end

%Store cell-array based uinformized data
fieldExists = isfield(planC{end}, 'structureArrayMore'); %this will be true for newer versions, false for old versions

if fieldExists %most common
    planC{planC{end}.structureArrayMore}(scanNum).indicesArray = indicesC;
    planC{planC{end}.structureArrayMore}(scanNum).bitsArray = structBitsC;
    planC{planC{end}.structureArrayMore}(scanNum).assocScanUID = planC{planC{end}.scan}(scanNum).scanUID;
    planC{planC{end}.structureArrayMore}(scanNum).structureSetUID = planC{planC{end}.structureArray}(scanNum).structureSetUID;
else
    structIndex = length(planC);
    planC{end+1} = planC{end}; %moves the index to the end
    %change index
    planC{end}.structureArrayMore = structIndex;
    if length(planC{structIndex}) == 1
        planC{structIndex} = struct('indicesArray', indicesC,...
            'bitsArray', structBitsC,...
            'assocScanUID',planC{planC{end}.scan}(scanNum).scanUID,...
            'structureSetUID', planC{planC{end}.structureArray}(scanNum).structureSetUID);
    else
        planC{structIndex}(scanNum) = struct('indicesArray', indicesC,...
            'bitsArray', structBitsC,...
            'assocScanUID',planC{planC{end}.scan}(scanNum).scanUID,...
            'structureSetUID', planC{planC{end}.structureArray}(scanNum).structureSetUID);

    end
end
