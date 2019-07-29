function tagS = gsps_module_tags
%"gsps_module_tags"
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
%APA 07/12/2019
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

%Graphic Annotation Sequence
tagS(end+1) = struct('tag', ['00700001'], 'type', ['1'], 'children', []);

child_0 = template;

%Referenced Image Sequence
child_0(end+1) = struct('tag', ['00081140'], 'type', ['1C'], 'children', image_SOP_instance_reference_macro_tags);

%Graphic layer
child_0(end+1) = struct('tag', ['00700002'], 'type', ['1'], 'children', []);

%Text object sequence
child_0(end+1) = struct('tag', ['00700008'], 'type', ['1C'], 'children', []);

        child_1 = template;

        %Bounding Box Annotation Units
        child_1(end+1) = struct('tag', ['00700003'], 'type', ['1C'], 'children', []);    

        %Anchor Point Annotation Units
        child_1(end+1) = struct('tag', ['00700004'], 'type', ['1C'], 'children', []);        
        
        %Unformatted Text Value
        child_1(end+1) = struct('tag', ['00700006'], 'type', ['1'], 'children', []);    
        
        %Bounding Box Top Left Hand Corner
        child_1(end+1) = struct('tag', ['00700010'], 'type', ['1C'], 'children', []);    

        %Bounding Box Bottom Right Hand Corner
        child_1(end+1) = struct('tag', ['00700011'], 'type', ['1C'], 'children', []);        

        %Bounding Box Text Horizontal Justification
        child_1(end+1) = struct('tag', ['00700012'], 'type', ['1C'], 'children', []);        

        %Anchor Point
        child_1(end+1) = struct('tag', ['00700014'], 'type', ['1C'], 'children', []);        

        %Anchor Point Visibility
        child_1(end+1) = struct('tag', ['00700015'], 'type', ['1C'], 'children', []);        

child_0(end).children = child_1;              
        
%Graphic object sequence
child_0(end+1) = struct('tag', ['00700009'], 'type', ['1'], 'children', []);

        child_2 = template;

        %Graphic Annotation Units
        child_2(end+1) = struct('tag', ['00700005'], 'type', ['1'], 'children', []);    

        %Graphic Dimensions
        child_2(end+1) = struct('tag', ['00700020'], 'type', ['1'], 'children', []);    
        
        %Number of Graphic Points
        child_2(end+1) = struct('tag', ['00700021'], 'type', ['1'], 'children', []);    
        
        %Graphic Data
        child_2(end+1) = struct('tag', ['00700022'], 'type', ['1'], 'children', []);  
        
        %Graphic Type
        child_2(end+1) = struct('tag', ['00700023'], 'type', ['1'], 'children', []);    
        
        %Graphic Filled
        child_2(end+1) = struct('tag', ['00700024'], 'type', ['1C'], 'children', []);   
        

child_0(end).children = child_2;              

tagS(end).children = child_0;

%Graphic Layer Sequence
tagS(end+1) = struct('tag', ['00700060'], 'type', ['1'], 'children', []);
        child_1 = template;

        %0070,0002  Graphic Layer
        child_1(end+1) = struct('tag', ['00700002'], 'type', ['1'], 'children', []);    

        %0070,0062  Graphic Layer Order
        child_1(end+1) = struct('tag', ['00700062'], 'type', ['1'], 'children', []);   
        
        %0070,0066  Graphic Layer Recommended Display Grayscale Value
        child_1(end+1) = struct('tag', ['00700066'], 'type', ['3'], 'children', []);
        
        %0070,0401  Graphic Layer Recommended Display CIELab Value
        child_1(end+1) = struct('tag', ['00700401'], 'type', ['3'], 'children', []);
        
        %0070,0068  Graphic Layer Description
        child_1(end+1) = struct('tag', ['00700068'], 'type', ['3'], 'children', []);

tagS(end).children = child_1;

        