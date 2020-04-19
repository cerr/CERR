function el = export_image_pixel_module_field(args)
%"export_image_pixel_module_field"
%   Given a single scan, return a properly populated image_pixel module tag
%   for use with any Composite Image IOD.  See image_pixel_module_tags.m.
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
%NAV 07/19/16 updated to dcm4che3
%   replaced ml2dcm_Element to data2dcmElement
%
%Usage:
%   dcmobj = export_image_pixel_module_field(args)
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

%Unpack input data.
tag         = args.tag;
type        = args.data{1};
template    = args.template;
switch type
    case 'scan'
        scanInfoS   = args.data{2};
        scanS       = args.data{3};        
    case 'dose'
        doseS       = args.data{2};
    otherwise
        error('Unsupported data passed to export_image_pixel_module_field.');   
end


switch tag
    
    case 2621442    %0028,0002 Samples per Pixel
        switch type
            case 'scan'
                data = 1;               %1 image plane in all CT/MR images.
            case 'dose'
                data = 1;               %1 image plane in dose.
        end
        el = data2dcmElement(template, data, tag);        
     
    case 2621444    %0028,0004 Photometric Interpretation
        data = 'MONOCHROME2';   %CT/MR have 0 black, maxVal white.  Same with dose.
        
    case 2621456    %0028,0010 Rows
        switch type
            case 'scan'
                data = scanInfoS.sizeOfDimension1;
            case 'dose'
                data = doseS.sizeOfDimension2;
        end
        el = data2dcmElement(template, data, tag);     

    case 2621457    %0028,0011 Columns
        switch type
            case 'scan'              
                data = scanInfoS.sizeOfDimension2;                
            case 'dose'
                data = doseS.sizeOfDimension1;
        end
        el = data2dcmElement(template, data, tag);       
        
    case 2621696    %0028,0100 Bits Allocated
        switch type
            case 'scan'
                data = 16;              %C.8.2.1.1.4 of PS 3.3 - 2006 
            case 'dose'
                data = 32;
        end
        el = data2dcmElement(template, data, tag);        
        
    case 2621697    %0028,0101 Bits Stored                                                                
        switch type
            case 'scan' %C.8.2.1.1.4 of PS 3.3 - 2006 
                        %Sloppy, consider revising.
                bools = [scanS.scanInfo.zValue] == scanInfoS.zValue;
                vals = scanS.scanArray(:,:,bools);
                maxV = max(vals(:));
                % apply scale factor
                scaleFactorV = args.data{4};
                scaleFactor = scaleFactorV(bools);
                maxV = uint16(maxV/scaleFactor);                
                log2s = log2(double(maxV));
                mostSignificantBit = floor(max(log2s)) + 1;
                data = max(mostSignificantBit, 12);
                data = min(data, 16);       
            case 'dose'
                data = 32;
        end                        
        el = data2dcmElement(template, data, tag);    

    case 2621698    %0028,0102 High Bit
        switch type
            case 'scan' %C.8.2.1.1.4 of PS 3.3 - 2006         
                        %Sloppy, consider revising.                                
                bools = [scanS.scanInfo.zValue] == scanInfoS.zValue;
                vals = scanS.scanArray(:,:,bools);
                maxV = max(vals(:));
                % apply scale factor
                scaleFactorV = args.data{4};
                scaleFactor = scaleFactorV(bools);
                maxV = uint16(maxV/scaleFactor);                
                log2s = log2(double(maxV));
                mostSignificantBit = floor(max(log2s)) + 1;
                data = max(mostSignificantBit, 12);
                data = min(data, 16);   
                data = data - 1;
            case 'dose'
                data = 32 - 1;
        end        
        el = data2dcmElement(template, data, tag);     
   
    case 2621699    %0028,0103 Pixel Representation
        switch type
            case 'scan'
                data = 0;               %0 = unsigned integer.
            case 'dose'
%wy                 switch upper(doseS.doseType)
%                     case 'ERROR'
%                         data = 1; %Two's Compliment Integer -- for ERROR does types, which may contain negative values.
%                     otherwise
%                         data = 0; %Unsigned Integer -- for all other dose types.
%                end
                if strcmpi(doseS.doseType, 'error')
                    data = 1;
                else
                    data = 0;
                end
%wy                
        end
        el = data2dcmElement(template, data, tag);      

    %Class 2 Tags -- Must be present, can be blank.       

    %Class 3 Tags -- presence is optional, currently undefined.
    case 2621702    %0028,0106 Smallest Image Pixel Value
    case 2621703    %0028,0107 Largest Image Pixel Value
    case 2629632    %0028,2000 ICC Profile

    %Class 1C Tags
    case 2654176    %0028,7FE0 Pixel Data Provider URL      
        %Currently not implemented.

    case 2145386512 %7FE0,0010 Pixel Data
        switch type
            case 'scan'
                sliceNum = find([scanS.scanInfo.zValue] == scanInfoS.zValue);
                data = scanS.scanArray(:,:,sliceNum);
                
                %Convert to unsigned 16-bit integer if scanArray is single
                scaleFactorV = args.data{4};
                scaleFactor = scaleFactorV(sliceNum);
                data = uint16(data/scaleFactor);
                
                data = data';
                data = data(:);
                
            case 'dose'  %Still alpha.  Need to look into why this flipping is necessary.
                nBits = 31;
                
                %Permute rows, columns since DICOM order is (Col, Row, Slc)
                data = permute(doseS.doseArray, [2 1 3]);
                
                %Flip the Z dimension.  As yet unknown why this is
                %necessary.
                data = flip(data, 3);

                %Flatten the data into a vector.
                data = data(:);
                
                %Determine the scaling factor to fit the data maxInt.
                maxABSDose = max(abs(data(:)));
                maxScaled  = 2^nBits;
                scaleFactor = maxABSDose ./ maxScaled;
                               
                data = data / scaleFactor; 
                
                data = uint32(data);
                
                data = bitstream_conversion_to('uint16', data);
        end
        
        el = data2dcmElement(template, data, tag);
        
    case 2621446    %0028,0006 Planar Configuration
    case 2621492    %0028,0034 Pixel Aspect Ratio
    case 2625793    %0028,1101 Red Palette Color Lookup Table Descriptor
    case 2625794    %0028,1102 Green Palette Color Lookup Table Descriptor
    case 2625795    %0028,1103 Blue Palette Color Lookup Table Descriptor
    case 2626049    %0028,1201 Red Palette Color Lookup Table Data
    case 2626050    %0028,1202 Green Palette Color Lookup Table Data
    case 2626051    %0028,1203 Blue Palette Color Lookup Table Data
        
    %Class 2C Tags        
    
    otherwise
        warning(['No methods exist to populate DICOM image_pixel module field ' dec2hex(tag,8) '.']);
        return;
end