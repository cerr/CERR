function planC = copyCERRStructure(structNum, planC)
%"copyCERRStructure"
%   Make a copy of the specified structure, appending it to the end of the
%   structure list.  The new structure takes the name of the original
%   structure, with "Copy of" appended to the front.  The uniformized data
%   of the structure is also created.
%
%JRA 3/28/05
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

%   planC = copyCERRStructure(structNum, planC)

global stateS
if ~exist('planC')
    global planC
end
indexS = planC{end};

%Take an exact copy of the structure.
newStruct = planC{indexS.structures}(structNum);

%Append "Copy of" to its name.
newStruct.structureName = ['Copy of ' newStruct.structureName];                                        

%Assign new UID to this structure
newStruct.strUID = createUID('structure');

%Place the duplicate at the end of the structure list.
newStructNum = length(planC{indexS.structures}) + 1;
planC{indexS.structures}(newStructNum) = newStruct;

%Update color
scanSet = getStructureAssociatedScan(newStructNum,planC);
assocScanV = getStructureAssociatedScan(1:length(planC{indexS.structures}),planC);
scanIndV = find(assocScanV==scanSet);
colorNum = length(scanIndV);
if isfield(stateS,'optS')
    color = stateS.optS.colorOrder( mod(colorNum-1, size(stateS.optS.colorOrder,1))+1,:);
else
    stateS.optS = CERROptions;
    color = stateS.optS.colorOrder( mod(colorNum-1, size(stateS.optS.colorOrder,1))+1,:);
end
planC{indexS.structures}(newStructNum).structureColor = color;

%Uniformize this new structure.
planC = updateStructureMatrices(planC, newStructNum);