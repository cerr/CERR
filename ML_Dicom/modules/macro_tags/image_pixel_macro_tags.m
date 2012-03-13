function tagS = image_pixel_macro_tags
%"image_pixel_macro_tags"
%   Returns the tags associated with the macro of an image pixel specified
%   by C.7.6.3.1 in PS3.3 of 2006 DICOM.
%
%JRA 06/06/06
%
%Usage:
%   tagS = image_pixel_macro_tags
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

%Samples per Pixel
tagS(end+1) = struct('tag', ['00280002'], 'type', ['1'], 'children', []);

%Photometric Interpretation
tagS(end+1) = struct('tag', ['00280004'], 'type', ['1'], 'children', []);

%Rows
tagS(end+1) = struct('tag', ['00280010'], 'type', ['1'], 'children', []);

%Columns
tagS(end+1) = struct('tag', ['00280011'], 'type', ['1'], 'children', []);

%Bits Allocated
tagS(end+1) = struct('tag', ['00280100'], 'type', ['1'], 'children', []);

%Bits Stored
tagS(end+1) = struct('tag', ['00280101'], 'type', ['1'], 'children', []);

%High Bit
tagS(end+1) = struct('tag', ['00280102'], 'type', ['1'], 'children', []);

%Pixel Representation
tagS(end+1) = struct('tag', ['00280103'], 'type', ['1'], 'children', []);

%Pixel Data
tagS(end+1) = struct('tag', ['7FE00010'], 'type', ['1C'], 'children', []);

%Planar Configuration
tagS(end+1) = struct('tag', ['00280006'], 'type', ['1C'], 'children', []);

%Pixel Aspect Ratio
tagS(end+1) = struct('tag', ['00280034'], 'type', ['1C'], 'children', []);

%Smallest Image Pixel Value
tagS(end+1) = struct('tag', ['00280106'], 'type', ['3'], 'children', []);

%Largest Image Pixel Value
tagS(end+1) = struct('tag', ['00280107'], 'type', ['3'], 'children', []);

%Red Palette Color Lookup Table Descriptor
tagS(end+1) = struct('tag', ['00281101'], 'type', ['1C'], 'children', []);

%Green Palette Color Lookup Table Descriptor
tagS(end+1) = struct('tag', ['00281102'], 'type', ['1C'], 'children', []);

%Blue Palette Color Lookup Table Descriptor
tagS(end+1) = struct('tag', ['00281103'], 'type', ['1C'], 'children', []);

%Red Palette Color Lookup Table Data
tagS(end+1) = struct('tag', ['00281201'], 'type', ['1C'], 'children', []);

%Green Palette Color Lookup Table Data
tagS(end+1) = struct('tag', ['00281202'], 'type', ['1C'], 'children', []);

%Blue Palette Color Lookup Table Data
tagS(end+1) = struct('tag', ['00281203'], 'type', ['1C'], 'children', []);

%ICC Profile
tagS(end+1) = struct('tag', ['00282000'], 'type', ['3'], 'children', []);