function tagS = content_item_macro_tags
%"content_item_macro_tags"
%   Returns the tags associated with a content item macro, 
%   specified by section 10.2 in PS3.3 of 2006 DICOM.
%
%JRA 06/06/06
%
%Usage:
%   tagS = content_item_macro_tags
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

%Initialize the tagS structure.
tagS = struct('tag', {}, 'type', {}, 'children', {});

%Create an empty tagS template for sequence creation.
template = tagS;

%Add tags based on PS3.3 attribute lists.

%Value Type
tagS(end+1) = struct('tag', ['0040A040'], 'type', ['1'], 'children', []);

%Concept Name Code Sequence
tagS(end+1) = struct('tag', ['0040A043'], 'type', ['1'], 'children', []);

%Reason for Requested Procedure Code Sequence
tagS(end+1) = struct('tag', ['0040100A'], 'type', ['3'], 'children', []);

    %Include Code Sequence Macro
    child_1 = code_sequence_macro_tags;
    tagS(end).children = child_1;
    
%DateTime
tagS(end+1) = struct('tag', ['0040A120'], 'type', ['1C'], 'children', []);

%Date
tagS(end+1) = struct('tag', ['0040A121'], 'type', ['1C'], 'children', []);

%Time
tagS(end+1) = struct('tag', ['0040A122'], 'type', ['1C'], 'children', []);    

%Person Name
tagS(end+1) = struct('tag', ['0040A123'], 'type', ['1C'], 'children', []);

%UID
tagS(end+1) = struct('tag', ['0040A124'], 'type', ['1C'], 'children', []);

%Text Value
tagS(end+1) = struct('tag', ['0040A160'], 'type', ['1C'], 'children', []);

%Concept Code Sequence
tagS(end+1) = struct('tag', ['0040A168'], 'type', ['1C'], 'children', []);

    %Include Code Sequence Macro
    child_1 = code_sequence_macro_tags;
    tagS(end).children = child_1;
    
%Numeric Value
tagS(end+1) = struct('tag', ['0040A30A'], 'type', ['1C'], 'children', []);    

%Measurement Units Code Sequence
tagS(end+1) = struct('tag', ['004008EA'], 'type', ['1C'], 'children', []);   

    %Include Code Sequence Macro
    child_1 = code_sequence_macro_tags;
    tagS(end).children = child_1;