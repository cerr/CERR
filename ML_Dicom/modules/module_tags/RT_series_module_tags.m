function tagS = RT_series_module_tags
%"RT_series_module_tags"
%   Return the tags used to represent a RT series as specified by  C.8.8.1 
%   in PS3.3 of 2006 DICOM specification. Tags are returned in a struct 
%   array with 3 fields:
%   
%   Tag: String containing hex DICOM tag of a field.
%  Type: String describing type of field, with 5 options:
%         '1' Field must exist, data must exist and be valid.
%         '2' Field must exist, data can exist and be valid, or be NULL.
%         '3' Field is optional, if the field exists data can exist and be
%             valid or be NULL.
%         '1C' Field must exist under certain conditions and contain valid
%             data.
%         '2C' Field must exist under certain conditions and can contain 
%             valid data or be NULL.
%Children: For sequences, a tagS with the same format as this struct array
%          containing the tags of child fields.
%
%JRA 06/06/06
%
%Usage:
%   tagS = RT_Series_module_tags
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
tagS = struct('tag', {}, 'tagdec', {}, 'type', {}, 'children', {});

%Create an empty tagS template for sequence creation.
template = tagS;

%Add tags based on PS3.3 attribute lists.

%Modality
tagS(end+1) = struct('tag', '00080060', 'tagdec', 524384, 'type', '1', 'children', []);

%Series Instance UID
tagS(end+1) = struct('tag', '0020000E', 'tagdec', 2097166, 'type', '1', 'children', []);

%Series Number
tagS(end+1) = struct('tag', '00200011', 'tagdec', 2097169, 'type', '2', 'children', []);

%Series Description
tagS(end+1) = struct('tag', '0008103E', 'tagdec', 528446, 'type', '3', 'children', []);

%Referenced Performed Procedure Step Sequence
tagS(end+1) = struct('tag', '00081111', 'tagdec', 528657, 'type', '3', 'children', []);
child_1      = template;

    %Referenced SOP Class UID
    child_1(end+1) = struct('tag', '00081150', 'tagdec', 528720, 'type', '1C', 'children', []);

    %Referenced SOP Instance UID
    child_1(end+1) = struct('tag', '00081155', 'tagdec', 528725, 'type', '1C', 'children', []);   
    tagS(end).children = child_1;
    
%Request Attributes Sequence
tagS(end+1) = struct('tag', '00400275', 'tagdec', 4194933, 'type', '3', 'children', []);

    %Request Attributes Macro
    child_1        = request_attributes_macro_tags;
    tagS(end).children = child_1;
    
%Performed Procedure Step ID
tagS(end+1) = struct('tag', '00400253', 'tagdec', 4194899, 'type', '3', 'children', []);

%Performed Procedure Step Start Date
tagS(end+1) = struct('tag', '00400244', 'tagdec', 4194884, 'type', '3', 'children', []);

%Performed Procedure Step Start Time
tagS(end+1) = struct('tag', '00400245', 'tagdec', 4194885, 'type', '3', 'children', []);

%Performed Procedure Step Description
tagS(end+1) = struct('tag', '00400254', 'tagdec', 4194900, 'type', '3', 'children', []);

%Performed Protocol Code Sequence
tagS(end+1) = struct('tag', '00400260', 'tagdec', 4194912, 'type', '3', 'children', []);

    %Code Sequence Macro
    child_1 = code_sequence_macro_tags;

    %Protocol Context Sequence
    child_1(end+1) = struct('tag', '00400440', 'tagdec', 4195392, 'type', '3', 'children', []);
    
        %Content Item Macro
        child_2 = content_item_macro_tags;

        %Content Item Modifier Sequence
        child_2(end+1) = struct('tag', '00400441', 'tagdec', 4195393, 'type', '3', 'children', []);
        
             %Content Item Macro
             child_3 = content_item_macro_tags;
             child_2(end).children = child_3;
             
        child_1(end).children = child_2;
    
    tagS(end).children = child_1;    