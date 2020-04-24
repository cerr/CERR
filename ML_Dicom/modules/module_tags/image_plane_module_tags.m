
function tagS = image_plane_module_tags
%"image_plane_module_tags"
%   Return the tags used to represent an image plane as specified by 
%   C.7.6.2 in PS3.3 of 2006 DICOM specification.
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
%   tagS = image_plane_module_tags
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

%Pixel Spacing
tagS(end+1) = struct('tag', ['00280030'], 'type', ['1'], 'children', []);

%Image Orientation (Patient)
tagS(end+1) = struct('tag', ['00200037'], 'type', ['1'], 'children', []);

%Image Position (Patient)
tagS(end+1) = struct('tag', ['00200032'], 'type', ['1'], 'children', []);

%Slice Thickness
tagS(end+1) = struct('tag', ['00180050'], 'type', ['2'], 'children', []);

%Slice Location
tagS(end+1) = struct('tag', ['00201041'], 'type', ['3'], 'children', []);

%Window center (1C)
tagS(end+1) = struct('tag', ['00281050'], 'type', ['1C'], 'children', []);

%Window width (1C)
tagS(end+1) = struct('tag', ['00281051'], 'type', ['1C'], 'children', []);

