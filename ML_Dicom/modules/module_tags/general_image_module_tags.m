function tagS = general_image_module_tags
%"general_image_module_tags"
%   Return the tags used to represent a general image as specified by 
%   C.7.6.1 in PS3.3 of 2006 DICOM specification.
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
%   tagS = general_image_module_tags
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

%Instance Number
tagS(end+1) = struct('tag', '00200013', 'tagdec', 2097171, 'type', '2', 'children', []);

%Patient Orientation
tagS(end+1) = struct('tag', '00200020', 'tagdec', 2097184, 'type', '2C', 'children', []);

%Content Date
tagS(end+1) = struct('tag', '00080023', 'tagdec', 524323, 'type', '2C', 'children', []);

%Content Time
tagS(end+1) = struct('tag', '00080033', 'tagdec', 524339, 'type', '2C', 'children', []);

%Image Type
tagS(end+1) = struct('tag', '00080008', 'tagdec', 524296, 'type', '3', 'children', []);

%Acquisition Number
tagS(end+1) = struct('tag', '00200012', 'tagdec', 2097170, 'type', '3', 'children', []);

%Acquisition Date
tagS(end+1) = struct('tag', '00080022', 'tagdec', 524322, 'type', '3', 'children', []);

%Acquisition Time
tagS(end+1) = struct('tag', '00080032', 'tagdec', 524338, 'type', '3', 'children', []);

%Acquisition Datetime
tagS(end+1) = struct('tag', '0008002A', 'tagdec', 524330, 'type', '3', 'children', []);

%Referenced Image Sequence
tagS(end+1) = struct('tag', '00081140', 'tagdec', 528704, 'type', '3', 'children', []);
child_1 = template;
    
    %Include Image SOP Instance Reference Macro
    child_1 = image_SOP_instance_reference_macro_tags;
    
    %Purpose of Reference Code Sequence
    child_1(end+1) = struct('tag', '0040A170', 'tagdec', 4235632, 'type', '3', 'children', []);
    child_2 = template;
            
        %Include Code Sequence Macro
        child_2 = code_sequence_macro_tags;
    
        child_1(end).children = child_2;
            
    tagS(end).children = child_1;
    
%Derivation Description
tagS(end+1) = struct('tag', '00082111', 'tagdec', 532753, 'type', '3', 'children', []);   

%Derivation Code Sequence
tagS(end+1) = struct('tag', '00089215', 'tagdec', 561685, 'type', '3', 'children', []);
child_1 = template;

    %Include Code Sequence Macro
    child_1 = code_sequence_macro_tags;
    
    tagS(end).children = child_1;
    
%Source Image Sequence
tagS(end+1) = struct('tag', '00082112', 'tagdec', 532754, 'type', '3', 'children', []);
    child_1 = template;
    
    %Include Image SOP Instance Reference Macro
    child_1 = image_SOP_instance_reference_macro_tags;
    
    %Purpose of Reference Code Sequence
    child_1(end+1) = struct('tag', '0040A170', 'tagdec', 4235632, 'type', '3', 'children', []);
    child_2 = template;
            
        %Include Code Sequence Macro
        child_2 = code_sequence_macro_tags;
    
        child_1(end).children = child_2;
        
    %Spatial Locations Preserved
    child_1(end+1) = struct('tag', '0028135A', 'tagdec', 2626394, 'type', '3', 'children', []);        
    
    tagS(end).children = child_1;
    
%Referenced Instance Sequence
tagS(end+1) = struct('tag', '0008114A', 'tagdec', 528714, 'type', '3', 'children', []);   
child_1 = template;

    %Referenced SOP Class UID
    child_1(end+1) = struct('tag', '00081150', 'tagdec', 528720, 'type', '1', 'children', []);        
    
    %Referenced SOP Instance UID
    child_1(end+1) = struct('tag', '00081155', 'tagdec', 528725, 'type', '1', 'children', []);            
    
    %Purpose of Reference Code Sequence
    child_1(end+1) = struct('tag', '0040A170', 'tagdec', 4235632, 'type', '1', 'children', []);                
    child_2 = template;
        
        %Include Code Sequence Macro
        child_2 = code_sequence_macro_tags;
        
        child_1(end).children = child_2;
        
    tagS(end).children = child_1;
    
%Images in Acquisition
tagS(end+1) = struct('tag', '00201002', 'tagdec', 2101250, 'type', '3', 'children', []);   

%Image Comments
tagS(end+1) = struct('tag', '00204000', 'tagdec', 2113536, 'type', '3', 'children', []);   

%Quality Control Image
tagS(end+1) = struct('tag', '00280300', 'tagdec', 2622208, 'type', '3', 'children', []);   

%Burned in Annotation
tagS(end+1) = struct('tag', '00280301', 'tagdec', 2622209, 'type', '3', 'children', []);   

%Lossy Image Compression
tagS(end+1) = struct('tag', '00282110', 'tagdec', 2629904, 'type', '3', 'children', []);   

%Lossy Image Compression Ratio
tagS(end+1) = struct('tag', '00282112', 'tagdec', 2629906, 'type', '3', 'children', []);   

%Lossy Image Compression Method
tagS(end+1) = struct('tag', '00282114', 'tagdec', 2629908, 'type', '3', 'children', []);   

%Icon Image Sequence
tagS(end+1) = struct('tag', '00880200', 'tagdec', 8913408, 'type', '3', 'children', []);   
child_1 = template;

    %Include "Image Pixel Macro"
    child_1 = image_pixel_macro_tags;
    
    tagS(end).children = child_1;
    
%Presentation LUT Shape
tagS(end+1) = struct('tag', '20500020', 'tagdec', 542113824, 'type', '3', 'children', []);   

%Irradiation Event UID
tagS(end+1) = struct('tag', '00083010', 'tagdec', 536592, 'type', '3', 'children', []);   
