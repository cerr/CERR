function tagS = general_series_module_tags
%"general_series_module_tags"
%   Return the tags used to represent a general series as specified by 
%   C.7.3.1 in PS3.3 of 2006 DICOM specification.
%
%   Tags are returned in a struct array with 3 fields:
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
%Children: For sequences, a tagS with the same format as this struct array.
%
%JRA 06/06/06
%
%Usage:
%   tagS = general_series_module_tags
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

%Modality
tagS(end+1) = struct('tag', ['00080060'], 'type', ['1'], 'children', []);

%Series Instance UID
tagS(end+1) = struct('tag', ['0020000E'], 'type', ['1'], 'children', []);

%Series Number
tagS(end+1) = struct('tag', ['00200011'], 'type', ['2'], 'children', []);

%Laterality
tagS(end+1) = struct('tag', ['00200060'], 'type', ['2C'], 'children', []);

%Series Date
tagS(end+1) = struct('tag', ['00080021'], 'type', ['3'], 'children', []);

%Series Time
tagS(end+1) = struct('tag', ['00080031'], 'type', ['3'], 'children', []);

%Performing Physician's Name
tagS(end+1) = struct('tag', ['00081050'], 'type', ['3'], 'children', []);

%Performing Physician Identification Sequence
tagS(end+1) = struct('tag', ['00081052'], 'type', ['3'], 'children', []);

    %Include "Person Identification Macro"
    child_1 = person_identification_macro_tags;
    
    tagS(end).children = child_1;
    
%Protocol Name
tagS(end+1) = struct('tag', ['00181030'], 'type', ['3'], 'children', []);    

%Series Description
tagS(end+1) = struct('tag', ['0008103E'], 'type', ['3'], 'children', []);

%Operator's Name
tagS(end+1) = struct('tag', ['00081070'], 'type', ['3'], 'children', []);

%Operator Identification Sequence
tagS(end+1) = struct('tag', ['00081072'], 'type', ['3'], 'children', []);
    
    %Include "Person Identification Macro"
    child_1 = person_identification_macro_tags;
    
    tagS(end).children = child_1;
    
%Referenced Performed Procedure Step Sequence
tagS(end+1) = struct('tag', ['00081111'], 'type', ['3'], 'children', []);    
child_1 = template;

    %Referenced SOP Class UID
    child_1(end+1) = struct('tag', ['00081150'], 'type', ['1C'], 'children', []);    
    
    %Referenced SOP Instance UID
    child_1(end+1) = struct('tag', ['00081155'], 'type', ['1C'], 'children', []);        
    
    tagS(end).children = child_1;
    
%Related Series Sequence
tagS(end+1) = struct('tag', ['00081250'], 'type', ['3'], 'children', []);        
child_1 = template;

    %Study Instance UID
    child_1(end+1) = struct('tag', ['0020000D'], 'type', ['1'], 'children', []);    
    
    %Series Instance UID
    child_1(end+1) = struct('tag', ['0020000E'], 'type', ['1'], 'children', []);        
    
    %Purpose of Reference Code Sequence
    child_1(end+1) = struct('tag', ['0040A170'], 'type', ['2'], 'children', []);        
    
        %Include "Code Sequence Macro"
        child_2 = code_sequence_macro_tags;
        
        child_1(end).children = child_2;
        
    tagS(end).children = child_1;
    
%Body Part Examined
tagS(end+1) = struct('tag', ['00180015'], 'type', ['3'], 'children', []);    

%Patient Position
tagS(end+1) = struct('tag', ['00185100'], 'type', ['2C'], 'children', []);    

%Smallest Pixel Value in Series
tagS(end+1) = struct('tag', ['00280108'], 'type', ['3'], 'children', []);    

%Largest Pixel Value in Series
tagS(end+1) = struct('tag', ['00280109'], 'type', ['3'], 'children', []);    

%Request Attributes Sequence
tagS(end+1) = struct('tag', ['00400275'], 'type', ['3'], 'children', []);    

    %Include "Request Attributes Macro"
    child_1 = request_attributes_macro_tags;
    
    tagS(end).children = child_1;
    
%Performed Procedure Step ID
tagS(end+1) = struct('tag', ['00400253'], 'type', ['3'], 'children', []);        

%Performed Procedure Step Start Date
tagS(end+1) = struct('tag', ['00400244'], 'type', ['3'], 'children', []);    

%Performed Procedure Step Start Time
tagS(end+1) = struct('tag', ['00400245'], 'type', ['3'], 'children', []);    

%Performed Procedure Step Description
tagS(end+1) = struct('tag', ['00400254'], 'type', ['3'], 'children', []);    

%Performed Protocol Code Sequence
tagS(end+1) = struct('tag', ['00400260'], 'type', ['3'], 'children', []);    

    %Include "Code Sequence Macro"
    child_1 = code_sequence_macro_tags;
    
    %Protocol Context Sequence
    child_1(end+1) = struct('tag', ['00400440'], 'type', ['3'], 'children', []);            
    
        %Include "Content Item Macro"
        child_2 = content_item_macro_tags;
        
        %Content Item Modifier Sequence
        child_2(end+1) = struct('tag', ['00400441'], 'type', ['3'], 'children', []);        
        
            %Include "Content Item Macro"
            child_3 = content_item_macro_tags;
            
            child_2(end).children = child_3;
            
        child_1(end).children = child_2;            
    
    tagS(end).children = child_1;        
    
%Comments on the Performed Procedure Step
tagS(end+1) = struct('tag', ['00400280'], 'type', ['3'], 'children', []);        
    