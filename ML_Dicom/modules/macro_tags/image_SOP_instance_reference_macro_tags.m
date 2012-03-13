function tagS = image_SOP_instance_reference_macro_tags
%"image_SOP_instance_reference_macro_tags"
%   Returns the tags associated with an image_SOP_instance reference, 
%   specified by section 10.3 in PS3.3 of 2006 DICOM.
%
%JRA 06/06/06
%
%Usage:
%   tagS = image_SOP_instance_reference_macro_tags
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

%Referenced SOP Class UID
tagS(end+1) = struct('tag', ['00081150'], 'type', ['1'], 'children', []);

%Referenced SOP Instance UID
tagS(end+1) = struct('tag', ['00081155'], 'type', ['1'], 'children', []);

%Referenced Frame Number
tagS(end+1) = struct('tag', ['00081160'], 'type', ['1C'], 'children', []);