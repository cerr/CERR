function struct = newCERRStructure(scanSet, planC, colorNum)
%"newCERRStructure"
%   Returns an empty, but valid CERR structure. This includes a null string
%   for the structure name and an appropriately formatted contour field.
%
%   scanSet is the index of the scan to register the new structure to.
%   This cannot be changed later.
%
%   Since structure contours require an item for each slice, a planC with 1+ valid 
%   scanSets must be in memory.
%   in memory.
%
%JRA 6/4/04
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
%Usage:
%   function struct = newCERRStructure(scanSet, planC)

global stateS

if ~exist('planC', 'var'); %wy
    global planC
end

indexS = planC{end};

%Get the structure template from initializeCERR.  
struct = initializeCERR('structures');

%Create and populate empty contour field.
try
    nSlices = size(getScanArray(planC{indexS.scan}(scanSet)), 3);
catch
    error('Cannot create new structure if scan is not valid.');
    return
end
segments.points = [];
[contour(1:nSlices).segments] = deal(segments);

%Create empty name field.
structureName = '';         

%Visibility defaults on.
visible = 1;

%Assign color for this structure
assocScanV = getStructureAssociatedScan(1:length(planC{indexS.structures}),planC);
scanIndV = find(assocScanV==scanSet);
if ~exist('colorNum','var')
    colorNum = length(scanIndV) + 1;
end
if ~isfield(stateS,'optS')
%     color = stateS.optS.colorOrder( mod(colorNum-1, size(stateS.optS.colorOrder,1))+1,:);
% else
    stateS.optS = opts4Exe([getCERRPath,'CERROptions.json']);
%     color = stateS.optS.colorOrder( mod(colorNum-1, size(stateS.optS.colorOrder,1))+1,:);
end
colorArr = stateS.optS.colorOrder;
color = setStructureColor(planC,colorArr);
%Assign these values to structure.
struct(1).contour        = contour;
struct(1).structureName  = structureName;
struct(1).visible        = visible;
struct(1).associatedScan = scanSet;
struct(1).assocScanUID   = planC{indexS.scan}(scanSet).scanUID;
struct(1).strUID         = createUID('structure');
struct(1).structureColor = color;
