function tagS = PT_image_module_tags
%"PT_image_module_tags"
%   Return the tags used to represent a PT image as specified by C.8.2.1 in
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
tagS = struct('tag', {}, 'tagdec', {}, 'type', {}, 'children', {});

%Create an empty tagS template for sequence creation.
template = tagS;

%Add tags based on PS3.3 attribute lists.

%Image Type
tagS(end+1) = struct('tag', '00080008', 'tagdec', 524296, 'type', '1', 'children', []);

%Samples per Pixel
tagS(end+1) = struct('tag', '00280002', 'tagdec', 2621442, 'type', '1', 'children', []);

%Photometric Interpretation
tagS(end+1) = struct('tag', '00280004', 'tagdec', 2621444, 'type', '1', 'children', []);

%Bits Allocated
tagS(end+1) = struct('tag', '00280100', 'tagdec', 2621696, 'type', '1', 'children', []);

%Bits Stored
tagS(end+1) = struct('tag', '00280101', 'tagdec', 2621697, 'type', '1', 'children', []);

%High Bit
tagS(end+1) = struct('tag', '00280102', 'tagdec', 2621698, 'type', '1', 'children', []);

%Rescale Intercept
tagS(end+1) = struct('tag', '00281052', 'tagdec', 2625618, 'type', '1', 'children', []);

%Rescale Slope
tagS(end+1) = struct('tag', '00281053', 'tagdec', 2625619, 'type', '1', 'children', []);

%KVP
tagS(end+1) = struct('tag', '00180060', 'tagdec', 1572960, 'type', '2', 'children', []);

%Acquisition Number
tagS(end+1) = struct('tag', '00200012', 'tagdec', 2097170, 'type', '2', 'children', []);

%Scan Options
tagS(end+1) = struct('tag', '00180022', 'tagdec', 1572898, 'type', '3', 'children', []);

%Data Collection Diameter
tagS(end+1) = struct('tag', '00180090', 'tagdec', 1573008, 'type', '3', 'children', []);

%Reconstruction Diameter
tagS(end+1) = struct('tag', '00181100', 'tagdec', 1577216, 'type', '3', 'children', []);

%Distance Source to Detector
tagS(end+1) = struct('tag', '00181110', 'tagdec', 1577232, 'type', '3', 'children', []);

%Distance Source to Patient
tagS(end+1) = struct('tag', '00181111', 'tagdec', 1577233, 'type', '3', 'children', []);

%Gantry/Detector Tilt
tagS(end+1) = struct('tag', '00181120', 'tagdec', 1577248, 'type', '3', 'children', []);

%Table Height
tagS(end+1) = struct('tag', '00181130', 'tagdec', 1577264, 'type', '3', 'children', []);

%Rotation Direction
tagS(end+1) = struct('tag', '00181140', 'tagdec', 1577280, 'type', '3', 'children', []);

%Exposure Time
tagS(end+1) = struct('tag', '00181150', 'tagdec', 1577296, 'type', '3', 'children', []);

%X-ray Tube Current
tagS(end+1) = struct('tag', '00181151', 'tagdec', 1577297, 'type', '3', 'children', []);

%Exposure
tagS(end+1) = struct('tag', '00181152', 'tagdec', 1577298, 'type', '3', 'children', []);

%Exposure in uAs
tagS(end+1) = struct('tag', '00181153', 'tagdec', 1577299, 'type', '3', 'children', []);

%Filter Type
tagS(end+1) = struct('tag', '00181160', 'tagdec', 1577312, 'type', '3', 'children', []);

%Generator Power
tagS(end+1) = struct('tag', '00181170', 'tagdec', 1577328, 'type', '3', 'children', []);

%Focal Spot
tagS(end+1) = struct('tag', '00181190', 'tagdec', 1577360, 'type', '3', 'children', []);

%Convolution Kernal
tagS(end+1) = struct('tag', '00181210', 'tagdec', 1577488, 'type', '3', 'children', []);

%Revolution Time
tagS(end+1) = struct('tag', '00189305', 'tagdec', 1610501, 'type', '3', 'children', []);

%Single Collimation Width
tagS(end+1) = struct('tag', '00189306', 'tagdec', 1610502, 'type', '3', 'children', []);

%Total Collimation Width
tagS(end+1) = struct('tag', '00189307', 'tagdec', 1610503, 'type', '3', 'children', []);

%Table Speed
tagS(end+1) = struct('tag', '00189309', 'tagdec', 1610505, 'type', '3', 'children', []);

%Table Feed per Rotation
tagS(end+1) = struct('tag', '00189310', 'tagdec', 1610512, 'type', '3', 'children', []);

%CT Pitch Factor
tagS(end+1) = struct('tag', '00189311', 'tagdec', 1610513, 'type', '3', 'children', []);

%Exposure Modulation Type
tagS(end+1) = struct('tag', '00189323', 'tagdec', 1610531, 'type', '3', 'children', []);

%Estimated Dose Saving
tagS(end+1) = struct('tag', '00189324', 'tagdec', 1610532, 'type', '3', 'children', []);

%CTDIvol
tagS(end+1) = struct('tag', '00189345', 'tagdec', 1610565, 'type', '3', 'children', []);

% PatientWeight
tagS(end+1) = struct('tag', '00101030', 'tagdec', 1052720, 'type', '3', 'children', []);

% Acquisition Time 
tagS(end+1) = struct('tag', '00080032', 'tagdec', 524338, 'type', '3', 'children', []);

%5505046    %0054,0016 Radiopharmaceutical Information Sequence
tagS(end+1) = struct('tag', '00540016', 'tagdec', 5505046, 'type', '2', 'children', []);
child_1     = template;
  
    %Radiopharmaceutical Start Time
    child_1(end+1) = struct('tag', '00181072', 'tagdec', 1577074, 'type', '3', 'children', []);  
    
    %Radionuclide Total Dose
    child_1(end+1) = struct('tag', '00181074', 'tagdec', 1577076, 'type', '3', 'children', []);
    
    %Radionuclide Half Life 
    child_1(end+1) = struct('tag', '00181075', 'tagdec', 1577077, 'type', '3', 'children', []);

%Optinally add the "General Anatomy Optional Macro"
% tagS = [tagS general_anatomy_optional_macro_tags];  %Currently unimplemented.

tagS(end).children = child_1;
