function tagS = ROI_contour_module_tags
%"ROI_contour_module_tags"
%   Return the tags used to represent a ROI contour specified by 
%   C.8.8.6 in PS3.3 of 2006 DICOM specification. Tags are returned in a 
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
%   tagS = ROI_contour_module_tags
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

%ROI Contour Sequence
tagS(end+1) = struct('tag', ['30060039'], 'type', ['1'], 'children', []);
child_1     = template;
  
    %Referenced ROI Number
    child_1(end+1) = struct('tag', ['30060084'], 'type', ['1'], 'children', []);    
    
    %ROI Display Color
    child_1(end+1) = struct('tag', ['3006002A'], 'type', ['3'], 'children', []);             
    
    %Contour Sequence
    child_1(end+1) = struct('tag', ['30060040'], 'type', ['3'], 'children', []);    
    child_2        = template;
    
        %Contour Number
        child_2(end+1) = struct('tag', ['30060048'], 'type', ['3'], 'children', []);    

        %Attached Contours
        child_2(end+1) = struct('tag', ['30060049'], 'type', ['3'], 'children', []);        
        
        %Contour Image Sequence
        child_2(end+1) = struct('tag', ['30060016'], 'type', ['3'], 'children', []);    
        child_3        = template;
        
            %Image SOP Instance Reference Macro
            child_3 = image_SOP_instance_reference_macro_tags;
            child_2(end).children = child_3;
            
        %Contour Geometric Type
        child_2(end+1) = struct('tag', ['30060042'], 'type', ['1C'], 'children', []);    
        
        %Contour Slab Thickness
        child_2(end+1) = struct('tag', ['30060044'], 'type', ['3'], 'children', []);            
        
        %Contour Offset Vector
        child_2(end+1) = struct('tag', ['30060045'], 'type', ['3'], 'children', []);            
        
        %Number of Contour Points
        child_2(end+1) = struct('tag', ['30060046'], 'type', ['1C'], 'children', []);                    
        
        %Contour Data
        child_2(end+1) = struct('tag', ['30060050'], 'type', ['1C'], 'children', []);            
        
        child_1(end).children = child_2;
        
   tagS(end).children = child_1;