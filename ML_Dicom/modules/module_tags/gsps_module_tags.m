function tagS = gsps_module_tags
%"gsps_module_tags"
%   Return the tags used to represent a ROI contour specified by 
%   A.33 in PS3.3 of 2006 DICOM specification. Tags are returned in a 
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
tagS = struct('tag', {}, 'tagdec', {}, 'type', {}, 'children', {});

%Create an empty tagS template for sequence creation.
template = tagS;

%Add tags based on PS3.3 attribute lists

% Presentation Creation Date
tagS(end+1) = struct('tag', '00700082', 'tagdec', 7340162, 'type', '1', 'children', []);

% Presentation Creation Time
tagS(end+1) = struct('tag', '00700083', 'tagdec', 7340163, 'type', '1', 'children', []);

% Presentation LUT Shape
tagS(end+1) = struct('tag', '20500020', 'tagdec', 542113824, 'type', '1C', 'children', []);

% Displayed Area Selection Sequence
tagS(end+1) = struct('tag', '0070005A', 'tagdec', 7340122, 'type', '1', 'children', []);

    child_0 = template;
    %Referenced Image Sequence
    child_0(end+1) = struct('tag', '00081140', 'tagdec', 528704, 'type', '1C', 'children', image_SOP_instance_reference_macro_tags);
    % Displayed Area Top Left Hand Corner
    child_0(end+1) = struct('tag', '00700052', 'tagdec', 7340114, 'type', '1', 'children', []);
    % Displayed Area Bottom Right Hand Corner
    child_0(end+1) = struct('tag', '00700053', 'tagdec', 7340115, 'type', '1', 'children', []);
    % Presentation Size Mode
    child_0(end+1) = struct('tag', '00700100', 'tagdec', 7340288, 'type', '1', 'children', []);
    % Presentation Pixel Spacing
    child_0(end+1) = struct('tag', '00700101', 'tagdec', 7340289, 'type', '1C', 'children', []);
    % Presentation Pixel Aspect Ratio
    child_0(end+1) = struct('tag', '00700102', 'tagdec', 7340290, 'type', '1C', 'children', []);
    % Presentation Pixel Magnification Ratio
    child_0(end+1) = struct('tag', '00700103', 'tagdec', 7340291, 'type', '1C', 'children', []);

tagS(end).children = child_0;

% Referenced Series Sequence
tagS(end+1) = struct('tag', '00081115', 'tagdec', 528661, 'type', '1', 'children', []);
    child_0 = template;
    % Series Instance UID
    child_0(end+1) = struct('tag', '0020000E', 'tagdec', 2097166, 'type', '1', 'children', []);
    % Referenced Image Sequence
    child_0(end+1) = struct('tag', '00081140', 'tagdec', 528704, 'type', '1', 'children', image_SOP_instance_reference_macro_tags);

tagS(end).children = child_0;

% Referenced Study Sequence


%Graphic Annotation Sequence
tagS(end+1) = struct('tag', '00700001', 'tagdec', 7340033, 'type', '1', 'children', []);

child_0 = template;

%Referenced Image Sequence
child_0(end+1) = struct('tag', '00081140', 'tagdec', 528704, 'type', '1C', 'children', image_SOP_instance_reference_macro_tags);

%Graphic layer
child_0(end+1) = struct('tag', '00700002', 'tagdec', 7340034, 'type', '1', 'children', []);

%Text object sequence
child_0(end+1) = struct('tag', '00700008', 'tagdec', 7340040, 'type', '1C', 'children', []);

        child_1 = template;

        %Bounding Box Annotation Units
        %child_1(end+1) = struct('tag', '00700003', 'tagdec',  , 'type', '1C', 'children', []);    

        %Anchor Point Annotation Units
        child_1(end+1) = struct('tag', '00700004', 'tagdec', 7340036, 'type', '1C', 'children', []);        
        
        %Unformatted Text Value
        child_1(end+1) = struct('tag', '00700006', 'tagdec', 7340038 , 'type', '1', 'children', []);    
        
        %Bounding Box Top Left Hand Corner
        %child_1(end+1) = struct('tag', '00700010', 'tagdec', 7340048, 'type', '1C', 'children', []);    

        %Bounding Box Bottom Right Hand Corner
        %child_1(end+1) = struct('tag', '00700011', 'tagdec', 7340049, 'type', '1C', 'children', []);        

        %Bounding Box Text Horizontal Justification
        %child_1(end+1) = struct('tag', '00700012', 'tagdec', 7340050, 'type', '1C', 'children', []);        

        %Anchor Point
        child_1(end+1) = struct('tag', '00700014', 'tagdec', 7340052, 'type', '1C', 'children', []);        

        %Anchor Point Visibility
        child_1(end+1) = struct('tag', '00700015', 'tagdec', 7340053, 'type', '1C', 'children', []);        

child_0(end).children = child_1;              
        
%Graphic object sequence
child_0(end+1) = struct('tag', '00700009', 'tagdec', 7340041, 'type', '1', 'children', []);

        child_2 = template;

        %Graphic Annotation Units
        child_2(end+1) = struct('tag', '00700005', 'tagdec', 7340037, 'type', '1', 'children', []);    

        %Graphic Dimensions
        child_2(end+1) = struct('tag', '00700020', 'tagdec', 7340064, 'type', '1', 'children', []);    
        
        %Number of Graphic Points
        child_2(end+1) = struct('tag', '00700021', 'tagdec', 7340065, 'type', '1', 'children', []);    
        
        %Graphic Data
        child_2(end+1) = struct('tag', '00700022', 'tagdec', 7340066, 'type', '1', 'children', []);  
        
        %Graphic Type
        child_2(end+1) = struct('tag', '00700023', 'tagdec', 7340067, 'type', '1', 'children', []);    
        
        %Graphic Filled
        child_2(end+1) = struct('tag', '00700024', 'tagdec', 7340068, 'type', '1C', 'children', []);   
        

child_0(end).children = child_2;              

tagS(end).children = child_0;

%Graphic Layer Sequence
tagS(end+1) = struct('tag', '00700060', 'tagdec', 7340128, 'type', '1', 'children', []);
        child_1 = template;

        %0070,0002  Graphic Layer
        child_1(end+1) = struct('tag', '00700002', 'tagdec', 7340034, 'type', '1', 'children', []);    

        %0070,0062  Graphic Layer Order
        child_1(end+1) = struct('tag', '00700062', 'tagdec', 7340130, 'type', '1', 'children', []);   
        
        %0070,0066  Graphic Layer Recommended Display Grayscale Value
        child_1(end+1) = struct('tag', '00700066', 'tagdec', 7340134, 'type', '3', 'children', []);
        
        %0070,0401  Graphic Layer Recommended Display CIELab Value
        child_1(end+1) = struct('tag', '00700401', 'tagdec', 7341057, 'type', '3', 'children', []);
        
        %0070,0068  Graphic Layer Description
        child_1(end+1) = struct('tag', '00700068', 'tagdec', 7340136, 'type', '3', 'children', []);

tagS(end).children = child_1;

        