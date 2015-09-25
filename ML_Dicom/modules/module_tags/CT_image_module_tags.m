function tagS = CT_image_module_tags
%"CT_image_module_tags"
%   Return the tags used to represent a CT image as specified by C.8.2.1 in
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
%JRA 06/06/06
%
%Usage:
%   tagS = CT_image_module_tags
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

%Image Type
tagS(end+1) = struct('tag', ['00080008'], 'type', ['1'], 'children', []);

%Samples per Pixel
tagS(end+1) = struct('tag', ['00280002'], 'type', ['1'], 'children', []);

%Photometric Interpretation
tagS(end+1) = struct('tag', ['00280004'], 'type', ['1'], 'children', []);

%Bits Allocated
tagS(end+1) = struct('tag', ['00280100'], 'type', ['1'], 'children', []);

%Bits Stored
tagS(end+1) = struct('tag', ['00280101'], 'type', ['1'], 'children', []);

%High Bit
tagS(end+1) = struct('tag', ['00280102'], 'type', ['1'], 'children', []);

%Rescale Intercept
tagS(end+1) = struct('tag', ['00281052'], 'type', ['1'], 'children', []);

%Rescale Slope
tagS(end+1) = struct('tag', ['00281053'], 'type', ['1'], 'children', []);

%KVP
tagS(end+1) = struct('tag', ['00180060'], 'type', ['2'], 'children', []);

%Acquisition Number
tagS(end+1) = struct('tag', ['00200012'], 'type', ['2'], 'children', []);

%Scan Options
tagS(end+1) = struct('tag', ['00180022'], 'type', ['3'], 'children', []);

%Data Collection Diameter
tagS(end+1) = struct('tag', ['00180090'], 'type', ['3'], 'children', []);

%Reconstruction Diameter
tagS(end+1) = struct('tag', ['00181100'], 'type', ['3'], 'children', []);

%Distance Source to Detector
tagS(end+1) = struct('tag', ['00181110'], 'type', ['3'], 'children', []);

%Distance Source to Patient
tagS(end+1) = struct('tag', ['00181111'], 'type', ['3'], 'children', []);

%Gantry/Detector Tilt
tagS(end+1) = struct('tag', ['00181120'], 'type', ['3'], 'children', []);

%Table Height
tagS(end+1) = struct('tag', ['00181130'], 'type', ['3'], 'children', []);

%Rotation Direction
tagS(end+1) = struct('tag', ['00181140'], 'type', ['3'], 'children', []);

%Exposure Time
tagS(end+1) = struct('tag', ['00181150'], 'type', ['3'], 'children', []);

%X-ray Tube Current
tagS(end+1) = struct('tag', ['00181151'], 'type', ['3'], 'children', []);

%Exposure
tagS(end+1) = struct('tag', ['00181152'], 'type', ['3'], 'children', []);

%Exposure in uAs
tagS(end+1) = struct('tag', ['00181153'], 'type', ['3'], 'children', []);

%Filter Type
tagS(end+1) = struct('tag', ['00181160'], 'type', ['3'], 'children', []);

%Generator Power
tagS(end+1) = struct('tag', ['00181170'], 'type', ['3'], 'children', []);

%Focal Spot
tagS(end+1) = struct('tag', ['00181190'], 'type', ['3'], 'children', []);

%Convolution Kernal
tagS(end+1) = struct('tag', ['00181210'], 'type', ['3'], 'children', []);

%Revolution Time
tagS(end+1) = struct('tag', ['00189305'], 'type', ['3'], 'children', []);

%Single Collimation Width
tagS(end+1) = struct('tag', ['00189306'], 'type', ['3'], 'children', []);

%Total Collimation Width
tagS(end+1) = struct('tag', ['00189307'], 'type', ['3'], 'children', []);

%Table Speed
tagS(end+1) = struct('tag', ['00189309'], 'type', ['3'], 'children', []);

%Table Feed per Rotation
tagS(end+1) = struct('tag', ['00189310'], 'type', ['3'], 'children', []);

%CT Pitch Factor
tagS(end+1) = struct('tag', ['00189311'], 'type', ['3'], 'children', []);

%Exposure Modulation Type
tagS(end+1) = struct('tag', ['00189323'], 'type', ['3'], 'children', []);

%Estimated Dose Saving
tagS(end+1) = struct('tag', ['00189324'], 'type', ['3'], 'children', []);

%CTDIvol
tagS(end+1) = struct('tag', ['00189345'], 'type', ['3'], 'children', []);



%Optinally add the "General Anatomy Optional Macro"
% tagS = [tagS general_anatomy_optional_macro_tags];  %Currently unimplemented.