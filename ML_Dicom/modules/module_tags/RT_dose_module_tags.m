function tagS = RT_dose_module_tags
%"RT_dose_module_tags"
%   Return the tags used to represent a RT dose as specified by C.8.8.3 in
%   PS3.3 of 2006 DICOM specification.
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
%JRA 07/10/06
%
%Usage:
%   tagS = RT_dose_module_tags
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

%Samples per Pixel
tagS(end+1) = struct('tag', '00280002', 'tagdec', 2621442, 'type', '1C', 'children', []);

%Photometric Interpretation
tagS(end+1) = struct('tag', '00280004', 'tagdec', 2621444, 'type', '1C', 'children', []);

%Bits Allocated
tagS(end+1) = struct('tag', '00280100', 'tagdec', 2621696, 'type', '1C', 'children', []);

%Bits Stored
tagS(end+1) = struct('tag', '00280101', 'tagdec', 2621697, 'type', '1C', 'children', []);

%High Bit
tagS(end+1) = struct('tag', '00280102', 'tagdec', 2621698, 'type', '1C', 'children', []);

%Pixel Representation
tagS(end+1) = struct('tag', '00280103', 'tagdec', 2621699, 'type', '1C', 'children', []);

%Dose Units
tagS(end+1) = struct('tag', '30040002', 'tagdec', 805568514, 'type', '1', 'children', []);

%Dose Type
tagS(end+1) = struct('tag', '30040004', 'tagdec', 805568516, 'type', '1', 'children', []);

%Instance Number
tagS(end+1) = struct('tag', '00200013', 'tagdec', 2097171, 'type', '3', 'children', []);

%Dose Comment
tagS(end+1) = struct('tag', '30040006', 'tagdec', 805568518, 'type', '3', 'children', []);

%Normalization Point
tagS(end+1) = struct('tag', '30040008', 'tagdec', 805568520, 'type', '3', 'children', []);

%Dose Summation Type
tagS(end+1) = struct('tag', '3004000A', 'tagdec', 805568522, 'type', '1', 'children', []);

%Referenced RT Plan Sequence
tagS(end+1) = struct('tag', '300C0002', 'tagdec', 806092802, 'type', '1C', 'children', []);
child_1 = template;

    %Referenced SOP Class UID
    child_1(end+1) = struct('tag', '00081150', 'tagdec', 528720, 'type', '1C', 'children', []);
    
    %Referenced SOP Instance UID
    child_1(end+1) = struct('tag', '00081155', 'tagdec', 528725, 'type', '1C', 'children', []);
    
    %Referenced Fraction Group Sequence
    child_1(end+1) = struct('tag', '300C0020', 'tagdec', 806092832, 'type', '1C', 'children', []);    
    child_2 = template;
    
        %Referenced Fraction Group Number
        child_2(end+1) = struct('tag', '300C0022', 'tagdec', 806092834, 'type', '1C', 'children', []);    
        
        %Referenced Beam Sequence
        child_2(end+1) = struct('tag', '300C0004', 'tagdec', 806092804, 'type', '1C', 'children', []);            
        child_3 = template;
        
            %Referenced Beam Number
            child_3(end+1) = struct('tag', '300C0006', 'tagdec', 806092806, 'type', '1C', 'children', []);            
            
            %Referenced Control Point Sequence
            child_3(end+1) = struct('tag', '300C00F2', 'tagdec', 806093042, 'type', '1C', 'children', []);                        
            child_4 = template;
            
                %Referenced Start Control Point Index
                child_4(end+1) = struct('tag', '300C00F4', 'tagdec', 806093044, 'type', '1', 'children', []);            
                
                %Referenced Stop Control Point Index
                child_4(end+1) = struct('tag', '300C00F6', 'tagdec', 806093046, 'type', '1', 'children', []);                            
                
                child_3(end).children = child_4;
                
            child_2(end).children = child_3;                
            
        %Referenced Brachy Application Setup Sequence
        child_2(end+1) = struct('tag', '300C000A', 'tagdec', 806092810, 'type', '1C', 'children', []); 
        child_3 = template;
            
            %Referenced Brachy Application Setup Number
            child_3(end+1) = struct('tag', '300C000C', 'tagdec', 806092812, 'type', '1C', 'children', []); 
            
            child_2(end).children = child_3;
            
        child_1(end).children = child_2;           
                
    tagS(end).children = child_1;
    
%Grid Frame Offset Vector
tagS(end+1) = struct('tag', '3004000C', 'tagdec', 805568524, 'type', '1C', 'children', []);    

%Dose Grid Scaling
tagS(end+1) = struct('tag', '3004000E', 'tagdec', 805568526, 'type', '1C', 'children', []);

%Tissue Heterogeneity Correction
tagS(end+1) = struct('tag', '30040014', 'tagdec', 805568532, 'type', '3', 'children', []);
    
