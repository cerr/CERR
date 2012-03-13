function tagS = request_attributes_macro_tags
%"request_attributes_macro_tags"
%   Returns the tags associated with an request attributes macro, 
%   specified by section 10.6 in PS3.3 of 2006 DICOM.
%
%JRA 06/06/06
%
%Usage:
%   tagS = request_attributes_macro_tags
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

%Requested Procedure ID
tagS(end+1) = struct('tag', ['00401001'], 'type', ['1'], 'children', []);

%Reason for the Requested Procedure
tagS(end+1) = struct('tag', ['00401002'], 'type', ['3'], 'children', []);

%Reason for Requested Procedure Code Sequence
tagS(end+1) = struct('tag', ['0040100A'], 'type', ['3'], 'children', []);

    %Include Code Sequence Macro
    child_1 = code_sequence_macro_tags;
    tagS(end).children = child_1;
    
%Scheduled Procedure Step ID
tagS(end+1) = struct('tag', ['00400009'], 'type', ['1'], 'children', []);

%Scheduled Procedure Step Description
tagS(end+1) = struct('tag', ['00400007'], 'type', ['3'], 'children', []);

%Scheduled Protocol Code Sequence
tagS(end+1) = struct('tag', ['00400008'], 'type', ['3'], 'children', []);

    %Include Code Sequence Macro
    child_1 = code_sequence_macro_tags;

    %Protocol Context Sequence
    child_1(end+1) = struct('tag', ['00400440'], 'type', ['3'], 'children', []);
    
    %Include Content Item Macro
        child_2 = content_item_macro_tags;
        
        %Content Item Modifier Sequence
        child_2(end+1) = struct('tag', ['00400441'], 'type', ['3'], 'children', []);
        
            %Include Content Item Macro
            child_3 = content_item_macro_tags;
            
            child_2(end).children = child_3;
        
        child_1(end).children = child_2;
        
    tagS(end).children = child_1;
        
    
    
    
    