function output = dissimilarInsert(dataStruct, newElement, index, nullData)
%"dissimilarInsert"
%   Add a dissimilar element to a datastructure, in position index.  If the 
%   element has more fields than the structure, the new fields are added to 
%   the structure and filled with nullData.  If the structure has more fields 
%   than the element, the reverse occurs. Any data in that position is
%   deleted, as it would be in a normal indexing operation. If index is blank
%   or not entered it is assumed to be the end, resulting in append.
%
%   If nulldata is undefined [] is used.
%
%JRA 10/7/03
%JOD, 10 Nov 03, define nullData if needed.  
%JRA, 10/1/04, Modifications to make compatible with ML6.1.
%JRA, 11/4/04, BugFix: Crashed if identical but misordered fieldnames.
%              Also added some more comments, and fixed initialization.
%
%Usage:
%   function output = dissimilarInsert(dataStruct, newElement, index, nullData)
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

%nullData defaults to [].
if nargin < 4
    nullData = [];
end

%Insert index defaults to appending.
if ~exist('index','var') || (exist('index','var') && isempty(index))
    index = length(dataStruct)+1;
end

%Get all fieldnames, find common fields.
structNames = fieldnames(dataStruct);
newNames = fieldnames(newElement);
commonNames = intersect(structNames,newNames);

%If same number of fields in both...
if length(commonNames) == length(structNames) && length(commonNames) == length(newNames)
    differences = find(~strcmpi(structNames, newNames));
    %If no differences...
    if isempty(differences)
        %then insert normally.
        dataStruct(index) = newElement;
    %If there were differences...    
    else
        %Fieldnames were identical but misordered, insert with reordering.
        for i=1:length(newNames)
            dataStruct = setfield(dataStruct, {index}, newNames{i}, getfield(newElement, newNames{i}));
        end
        %warning('Element''s fieldnames were misordered, but the same.')
    end
    output = dataStruct;
    return;
end

%If more fields in new element...
if length(commonNames) < length(newNames)
    newFieldsForStruct = setdiff(newNames, commonNames);
    for i = 1:length(newFieldsForStruct)
        %dataStruct = setfield(dataStruct, {}, newFieldsForStruct{i}, []);
        for j=1:length(dataStruct)
            dataStruct = setfield(dataStruct, {j}, newFieldsForStruct{i}, nullData);
        end
    end
end

%If more fields in data structure...
if length(commonNames) < length(structNames)
    newFieldsForElement = setdiff(structNames, commonNames);
    for i=1:length(newFieldsForElement)
        newElement = setfield(newElement, newFieldsForElement{i}, nullData);
    end
end

%Now actually perform the insert.
finalNames = fieldnames(newElement);
siz = size(dataStruct);
if prod(siz) == 0
    indV = 1:2:2*length(finalNames);
    argV = {};
    [argV{indV}] = deal(finalNames{:});
    argV{end+1} = [];
    dataStruct = struct(argV{:});    
end

for i=1:length(finalNames)           
    dataStruct = setfield(dataStruct, {index}, finalNames{i}, getfield(newElement, finalNames{i}));
end
output = dataStruct;
return;