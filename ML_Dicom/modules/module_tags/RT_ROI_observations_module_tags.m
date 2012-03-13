function tagS = RT_ROI_observations_module_tags
%"RT_ROI_observations_module_tags"
%   Return the tags used to represent a RT ROI observation specified by 
%   C.8.8.8 in PS3.3 of 2006 DICOM specification. Tags are returned in a 
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
%   tagS = RT_ROI_observations_module_tags
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

%RT ROI Observations Sequence
tagS(end+1) = struct('tag', ['30060080'], 'type', ['1'], 'children', []);
child_1     = template;

    %Observation Number
    child_1(end+1) = struct('tag', ['30060082'], 'type', ['1'], 'children', []);
    
    %Referenced ROI Number
    child_1(end+1) = struct('tag', ['30060084'], 'type', ['1'], 'children', []);    
    
    %ROI Observation Label
    child_1(end+1) = struct('tag', ['30060085'], 'type', ['3'], 'children', []);    
    
    %Referenced ROI Description
    child_1(end+1) = struct('tag', ['30060088'], 'type', ['3'], 'children', []);    
    
    %RT Related ROI Sequence
    child_1(end+1) = struct('tag', ['30060030'], 'type', ['3'], 'children', []);    
    child_2        = template;
    
        %Referenced ROI Number
        child_2(end+1) = struct('tag', ['30060084'], 'type', ['1C'], 'children', []);    
        
        %RT ROI Relationship
        child_2(end+1) = struct('tag', ['30060033'], 'type', ['3'], 'children', []);    
    
        child_1(end).children = child_2;
        
    %RT ROI Identification Code Sequence
    child_1(end+1) = struct('tag', ['30060086'], 'type', ['3'], 'children', []);    
    child_2        = template;
    
        child_2 = code_sequence_macro_tags;
        
        child_1(end).children = child_2;
        
    %Related RT ROI Observations Sequence
    child_1(end+1) = struct('tag', ['300600A0'], 'type', ['3'], 'children', []);    
    child_2        = template;
    
        %Observation Number
        child_2(end+1) = struct('tag', ['30060082'], 'type', ['1C'], 'children', []);    
        
        child_1(end).children = child_1;
        
    %RT ROI Interpreted Type
    child_1(end+1) = struct('tag', ['300600A4'], 'type', ['2'], 'children', []);       
    
    %ROI Interpreter
    child_1(end+1) = struct('tag', ['300600A6'], 'type', ['2'], 'children', []);           
    
    %Material ID
    child_1(end+1) = struct('tag', ['300A00E1'], 'type', ['3'], 'children', []);           
    
    %ROI Physical Properties Sequence
    child_1(end+1) = struct('tag', ['300600B0'], 'type', ['3'], 'children', []);           
    child_2        = template;
    
        %ROI Physical Property
        child_2(end+1) = struct('tag', ['300600B2'], 'type', ['1C'], 'children', []);           
        
        %ROI Physical Property Value
        child_2(end+1) = struct('tag', ['300600B4'], 'type', ['1C'], 'children', []);           
        
        child_1(end).children = child_2;
        
    tagS(end).children = child_1;