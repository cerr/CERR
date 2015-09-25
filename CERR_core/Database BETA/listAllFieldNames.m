function fieldnames = listAllFieldNames(planC)
% List all fieldnames in the plan.
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


indexS = planC{end};
cellNames = fields(indexS);
for i=1:length(cellNames)
    cellVals(i) = indexS.(cellNames{i});
end

fieldnames = [];
%Call listFields on each cell in planC.  Manually generate the index alias.
for i=1:length(cellNames)
    fieldnames = [fieldnames;listFields(planC{cellVals(i)}, ['planC{indexS.' cellNames{i} '}'])];
end
fieldnames = unique(fieldnames);

function fieldnames = listFields(structure, myName)
% list fields in struct given the name of the structure above.
fieldnames = {myName};
dataType = class(structure); 
switch dataType   
    case 'struct'      
        for i=1:length(structure(:))
            fieldNames = fields(structure);
            for j=1:length(fieldNames)                           
                childName = [myName '.' fieldNames{j}];
                childFields = listFields(structure(i).(fieldNames{j}), childName);
                fieldnames = [fieldnames;childFields];    
            end
        end      
end