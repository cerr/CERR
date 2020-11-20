function tagS = MR_image_module_tags_subset
%"MR_image_module_tags_subset"
%   Return a subset of the tags specified in C.7.3.1 in PS3.3 
%   of the 2006 DICOM specification required for distinguishing MR series'.
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
%AI 11/20/2020
%
%Usage:
%   tagS = MR_image_module_tags_subset
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

% Acquisition Time
tagS(end+1) = struct('tag', ['00080032'], 'type', ['3'], 'children', []);

% b-value for MR scans
tagS(end+1) = struct('tag', ['00431039'], 'type', ['4'], 'children', []); % GE    
tagS(end+1) = struct('tag', ['00189087'], 'type', ['4'], 'children', []); % Philips    
tagS(end+1) = struct('tag', ['0019100C'], 'type', ['4'], 'children', []); % SIEMENS   

% Temporal position ID
tagS(end+1) = struct('tag', ['00200100'], 'type', ['3'], 'children', []);  

%Trigger time  
tagS(end+1) = struct('tag', ['00181060'], 'type', ['2C'], 'children', []);  

%Number of slices (for GE data)
tagS(end+1) = struct('tag', ['0021104F'], 'type', ['3'], 'children', []);  

%Instance number
tagS(end+1) = struct('tag', ['00200013'], 'type', ['1'], 'children', []);  

%Manufacturer
tagS(end+1) = struct('tag', ['00080070'], 'type', ['2'], 'children', []);  