function tagS = general_study_module_tags
%"general_study_module_tags"
%   Return the tags used to represent a general study as specified by 
%   C.7.2.1 in PS3.3 of 2006 DICOM specification.
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
%   tagS = general_study_module_tags
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

%Study Instance UID
tagS(end+1) = struct('tag', ['0020000D'], 'type', ['1'], 'children', []);

%Study Date
tagS(end+1) = struct('tag', ['00080020'], 'type', ['2'], 'children', []);

%Study Time
tagS(end+1) = struct('tag', ['00080030'], 'type', ['2'], 'children', []);

%Referring Physician's Name
tagS(end+1) = struct('tag', ['00080090'], 'type', ['2'], 'children', []);

%Referring Physician Identification Sequence
tagS(end+1) = struct('tag', ['00080096'], 'type', ['3'], 'children', []);

    %Include "Person Identification Macro"
    child_1 = person_identification_macro_tags;
    
    tagS(end).children = child_1;
    
%Study ID
tagS(end+1) = struct('tag', ['00200010'], 'type', ['2'], 'children', []);

%Accession Number
tagS(end+1) = struct('tag', ['00080050'], 'type', ['2'], 'children', []);

%Study Description
tagS(end+1) = struct('tag', ['00081030'], 'type', ['3'], 'children', []);

%Physician(s) of Record
tagS(end+1) = struct('tag', ['00081048'], 'type', ['3'], 'children', []);

%Physician(s) of Record Identification Sequence
tagS(end+1) = struct('tag', ['00081049'], 'type', ['3'], 'children', []);

    %Include "Person Identification Macro"
    child_1 = person_identification_macro_tags;
    
    tagS(end).children = child_1;
    
%Name of Physician(s) Reading Study
tagS(end+1) = struct('tag', ['00081060'], 'type', ['3'], 'children', []);    

%Physician(s) Reading Study Identification Sequence
tagS(end+1) = struct('tag', ['00081062'], 'type', ['3'], 'children', []);    

    %Include "Person Identification Macro"
    child_1 = person_identification_macro_tags;
    
    tagS(end).children = child_1;

%Referenced Study Sequence
tagS(end+1) = struct('tag', ['00081110'], 'type', ['3'], 'children', []);    
child_1 = template;

    %Referenced SOP Class UID
    child_1(end+1) = struct('tag', ['00081150'], 'type', ['1C'], 'children', []);    

    %Referenced SOP Instance UID
    child_1(end+1) = struct('tag', ['00081155'], 'type', ['1C'], 'children', []);    

    tagS(end).children = child_1;
    
%Procedure Code Sequence
tagS(end+1) = struct('tag', ['00081032'], 'type', ['3'], 'children', []);    

    %Include "Code Sequence Macro"
    child_1 = code_sequence_macro_tags;
    
    tagS(end).children = child_1;







