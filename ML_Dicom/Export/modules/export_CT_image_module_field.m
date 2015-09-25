function el = export_CT_image_module_field(args)
%"export_CT_image_module_field"
%   Given a single scan, return a properly populated CT_image module tag
%   for use with any Composite Image IOD.  See CT_image_module_tags.m.
%
%   For speed, tag must be a decimal representation of the 8 digit
%   hexidecimal DICOM tag desired, ie instead of '00100010', pass
%   hex2dec('00100010');
%
%   Arguments are passed in a structure, arg:
%       arg.tag         = decimal tag of field to fill
%       arg.data        = CERR structure(s) to fill from
%       arg.template    = an empty template of the module created by the
%                         function build_module_template.m
%
%   This function requires arg.data = {scanInfoS, scanS};
%
%JRA 06/19/06
%
%Usage:
%   dcmobj = export_CT_image_module_field(args)
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

%Init output element to empty.
el = [];

%Unpack input parameters.
tag         = args.tag;
scanInfoS   = args.data{1};
scanS       = args.data{2};
template    = args.template;

switch tag
    %Class 1 Tags -- Required, must have data.
    case 524296     %0008,0008 Image Type
        data = {'ORIGINAL', 'PRIMARY', 'AXIAL'};
        el = template.get(tag);
        el = ml2dcm_Element(el, data);

    case 2621442    %0028,0002 Samples per Pixel
        data = 1;               %1 image plane in all CT/MR images.
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
     
    case 2621444    %0028,0004 Photometric Interpretation
        data = 'MONOCHROME2';   %CT/MR have 0 black, maxVal white.
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 2621456    %0028,0010 Rows
        data = scanInfoS.sizeOfDimension1;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);

    case 2621457    %0028,0011 Columns
        data = scanInfoS.sizeOfDimension2;                
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 2621696    %0028,0100 Bits Allocated
        data = 16;              %C.8.2.1.1.4 of PS 3.3 - 2006 
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 2621697    %0028,0101 Bits Stored
                                %C.8.2.1.1.4 of PS 3.3 - 2006 
                                %Sloppy, consider revising.
        bools = [scanS.scanInfo.zValue] == scanInfoS.zValue;
        vals = scanS.scanArray(:,:,bools);
        maxV = max(vals(:));
        log2s = log2(double(maxV));
        mostSignificantBit = floor(max(log2s)) + 1;
        data = max(mostSignificantBit, 12);
        data = min(data, 16);       
        el = template.get(tag);
        el = ml2dcm_Element(el, data);

    case 2621698    %0028,0102 High Bit
                                %C.8.2.1.1.4 of PS 3.3 - 2006         
                                %Sloppy, consider revising.                                
        bools = [scanS.scanInfo.zValue] == scanInfoS.zValue;
        vals = scanS.scanArray(:,:,bools);
        maxV = max(vals(:));
        log2s = log2(double(maxV));
        mostSignificantBit = floor(max(log2s)) + 1;
        data = max(mostSignificantBit, 12);
        data = min(data, 16);   
        data = data - 1;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 2625618    %0028,1052 Rescale Intercept
        ctO = scanInfoS.CTOffset;
        data = -ctO;           %CERR exports stored values as 1*HU + CTOffset.
        el = template.get(tag);
        el = ml2dcm_Element(el, data);

    case 2625619    %0028,1053 Rescale Slope
        %data = 1;
        %data = scanInfoS.rescaleSlope;
        data = args.data{3}; %APA: factor for conversion to uint16 for modalities other than CT
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    %Class 2 Tags -- Must be present, can be NULL.       
    case 1572960    %0018,0060 KVP
        el = template.get(tag);

    case 2097170    %0020,0012 Acqusition Number
        el = template.get(tag);
        
    %Class 3 Tags -- presence is optional, currently undefined.
    case 1572898    %0018,0022 Scan Options
    case 1573008    %0018,0090 Data Collection Diameter
    case 1577216    %0018,1100 Reconstruction Diameter
    case 1577232    %0018,1110 Distance Source to Detector
    case 1577233    %0018,1111 Distance Source to Patient
    case 1577248    %0018,1120 Gantry/Detector Tilt
    case 1577264    %0018,1130 Table Height
    case 1577280    %0018,1140 Rotation Direction
    case 1577296    %0018,1150 Exposure Time
    case 1577297    %0018,1151 X-ray Tube Current
    case 1577298    %0018,1152 Exposure
    case 1577299    %0018,1153 Exposure in microAs
    case 1577312    %0018,1160 Filter Type
    case 1577328    %0018,1170 Generator Power
    case 1577360    %0018,1190 Focal Spot
    case 1577488    %0018,1210 Convolution Kernal
    case 1610501    %0018,9305 Revolution Time
    case 1610502    %0018,9306 Single Collimation Width
    case 1610503    %0018,9307 Total Collimation Width
    case 1610505    %0018,9309 Table Speed
    case 1610512    %0018,9310 Table Feed per Rotation
    case 1610513    %0018,9311 CT Pitch Factor
    case 1610531    %0018,9323 Exposure Modulation Type
    case 1610532    %0018,9324 Estimated Dose Saving
    case 1610565    %0018,9345 CTDIvol
    
    %Class 1C Tags
            
    %Class 2C Tags        
    
    otherwise
        warning(['No methods exist to populate DICOM image_pixel module field ' dec2hex(tag,8) '.']);
        return;
end