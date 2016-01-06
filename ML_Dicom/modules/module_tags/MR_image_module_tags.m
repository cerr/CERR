function tagS = MR_image_module_tags
%"MR_image_module_tags"
%   Return the tags used to represent an MRI Image as specified by 
%   C.7.3.1 in PS3.3 of 2006 DICOM specification.
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
%APA 12/11/2015
%
%Usage:
%   tagS = MR_image_module_tags
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

%Series Instance UID
tagS(end+1) = struct('tag', ['0020000E'], 'type', ['1'], 'children', []);

%Series Number
tagS(end+1) = struct('tag', ['00200011'], 'type', ['2'], 'children', []);

%Laterality
tagS(end+1) = struct('tag', ['00200060'], 'type', ['2C'], 'children', []);

%Series Date
tagS(end+1) = struct('tag', ['00080021'], 'type', ['3'], 'children', []);

%Series Time
tagS(end+1) = struct('tag', ['00080031'], 'type', ['3'], 'children', []);

% Acquisition Time
tagS(end+1) = struct('tag', ['00080032'], 'type', ['3'], 'children', []);

% b-value for MR scans
tagS(end+1) = struct('tag', ['00431039'], 'type', ['4'], 'children', []); % GE    
tagS(end+1) = struct('tag', ['00189087'], 'type', ['4'], 'children', []); % Philips    
tagS(end+1) = struct('tag', ['0019100C'], 'type', ['4'], 'children', []); % SIEMENS    

    