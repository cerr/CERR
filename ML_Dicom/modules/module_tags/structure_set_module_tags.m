function tagS = structure_set_module_tags
%"structure_set_module_tags"
%   Return the tags used to represent a structure set as specified by 
%   C.8.8.5 in PS3.3 of 2006 DICOM specification. Tags are returned in a 
%   struct array with 3 fields:
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
%   tagS = structure_set_module_tags
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

%Structure Set Label
tagS(end+1) = struct('tag', '30060002', 'tagdec', 805699586, 'type', '1', 'children', []);

%Structure Set Name
tagS(end+1) = struct('tag', '30060004', 'tagdec', 805699588, 'type', '3', 'children', []);

%Structure Set Description
tagS(end+1) = struct('tag', '30060006', 'tagdec', 805699590, 'type', '3', 'children', []);

%Instance Number
tagS(end+1) = struct('tag', '00200013', 'tagdec', 2097171, 'type', '3', 'children', []);

%Structure Set Date
tagS(end+1) = struct('tag', '30060008', 'tagdec', 805699592, 'type', '2', 'children', []);

%Structure Set Time
tagS(end+1) = struct('tag', '30060009', 'tagdec', 805699593, 'type', '2', 'children', []);

%Referenced Frame of Reference Sequence
tagS(end+1) = struct('tag', '30060010', 'tagdec', 805699600, 'type', '3', 'children', []);
child_1      = template;

    %Frame of Reference UID
    child_1(end+1) = struct('tag', '00200052', 'tagdec', 2097234, 'type', '1C', 'children', []);
    
    %Frame of Reference Relationship Sequence
    child_1(end+1) = struct('tag', '300600C0', 'tagdec', 805699776, 'type', '3', 'children', []);
    child_2        = template;
        
        %Related Frame of Reference UID
        child_2(end+1) = struct('tag', '300600C2', 'tagdec', 805699778, 'type', '1C', 'children', []);
        
        %Frame of Reference Transformation Type
        child_2(end+1) = struct('tag', '300600C4', 'tagdec', 805699780, 'type', '1C', 'children', []);
    
        %Frame of Reference Transformation Matrix
        child_2(end+1) = struct('tag', '300600C6', 'tagdec', 805699782, 'type', '1C', 'children', []);
        
        %Frame of Reference Transformation Comment
        child_2(end+1) = struct('tag', '300600C8', 'tagdec', 805699784, 'type', '3', 'children', []);
        child_1(end).children = child_2;
        
    %RT Referenced Study Sequence
    child_1(end+1) = struct('tag', '30060012', 'tagdec', 805699602, 'type', '3', 'children', []);    
    child_2        = template;
    
        %Referenced SOP Class UID
        child_2(end+1) = struct('tag', '00081150', 'tagdec', 528720, 'type', '1C', 'children', []);

        %Referenced SOP Instance UID
        child_2(end+1) = struct('tag', '00081155', 'tagdec', 528725, 'type', '1C', 'children', []);
        
        %RT Referenced Series Sequence
        child_2(end+1) = struct('tag', '30060014', 'tagdec', 805699604, 'type', '1C', 'children', []);
        child_3        = template;
        
            %Series Instance UID
            child_3(end+1) = struct('tag', '0020000E', 'tagdec', 2097166, 'type', '1C', 'children', []);
            
            %Contour Image Sequence
            child_3(end+1) = struct('tag', '30060016', 'tagdec', 805699606, 'type', '1C', 'children', []);
            child_4        = template;
                
                %Image SOP Instance Reference Macro -- Not a single tag.
                child_4        = image_SOP_instance_reference_macro_tags;

                child_3(end).children = child_4;
                
            child_2(end).children = child_3;
            
        child_1(end).children = child_2;
        
    tagS(end).children = child_1;
    
%Structure Set ROI Sequence
tagS(end+1) = struct('tag', '30060020', 'tagdec', 805699616, 'type', '3', 'children', []);                
child_1     = template;

    %ROI Number
    child_1(end+1) = struct('tag', '30060022', 'tagdec', 805699618, 'type', '1C', 'children', []);        
    
    %Referenced Frame of Reference UID
    child_1(end+1) = struct('tag', '30060024', 'tagdec', 805699620, 'type', '1C', 'children', []);        
    
    %ROI Name
    child_1(end+1) = struct('tag', '30060026', 'tagdec', 805699622, 'type', '2C', 'children', []);        
    
    %ROI Description
    child_1(end+1) = struct('tag', '30060028', 'tagdec', 805699624, 'type', '3', 'children', []);        
    
    %ROI Volume
    child_1(end+1) = struct('tag', '3006002C', 'tagdec', 805699628, 'type', '3', 'children', []);        
    
    %ROI Generation Algorithm
    child_1(end+1) = struct('tag', '30060036', 'tagdec', 805699638, 'type', '2C', 'children', []);        
    
    %ROI Generation Description
    child_1(end+1) = struct('tag', '30060038', 'tagdec', 805699640, 'type', '3', 'children', []);        

    tagS(end).children = child_1;
    
    
        
    