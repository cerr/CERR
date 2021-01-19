function tagS = general_equipment_module_tags
%"general_equipment_module_tags"
%   Return the tags used to represent a general equipment module as 
%   specified by C.7.5.1 in PS3.3 of 2006 DICOM specification.
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
%   tagS = general_equipment_module_tags
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
%template = tagS;

%Add tags based on PS3.3 attribute lists.

%Manufacturer
tagS(end+1) = struct('tag', '00080070', 'tagdec', 524400, 'type', '2', 'children', []);

%Institution Name
tagS(end+1) = struct('tag', '00080080', 'tagdec', 524416, 'type', '2', 'children', []);

%Institution Address
tagS(end+1) = struct('tag', '00080081', 'tagdec', 524417, 'type', '3', 'children', []);

%Station Name
tagS(end+1) = struct('tag', '00081010', 'tagdec', 528400, 'type', '3', 'children', []);

%Institutional Department Name
tagS(end+1) = struct('tag', '00081040', 'tagdec', 528448, 'type', '3', 'children', []);

%Manufacturer's Model Name
tagS(end+1) = struct('tag', '00081090', 'tagdec', 528528, 'type', '3', 'children', []);

%Device Serial Number
tagS(end+1) = struct('tag', '00181000', 'tagdec', 1576960, 'type', '3', 'children', []);

%Software Versions
tagS(end+1) = struct('tag', '00181020', 'tagdec', 1576992, 'type', '3', 'children', []);

%Spatial Resolution
tagS(end+1) = struct('tag', '00181050', 'tagdec', 1577040, 'type', '3', 'children', []);

%Date of Last Calibration
tagS(end+1) = struct('tag', '00181200', 'tagdec', 1577472, 'type', '3', 'children', []);

%Time of Last Calibration
tagS(end+1) = struct('tag', '00181201', 'tagdec', 1577473, 'type', '3', 'children', []);

%Pixel Padding Value
tagS(end+1) = struct('tag', '00280120', 'tagdec', 2621728, 'type', '3', 'children', []);