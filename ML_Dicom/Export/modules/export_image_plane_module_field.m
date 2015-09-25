function el = export_image_plane_module_field(args)
%"export_image_plane_module_field"
%   Given a single scan, return a properly populated image_plane module tag
%   for use with any Composite Image IOD.  See image_plane_module_tags.m.
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
%   This function requires arg.data = {'scan', scanInfoS, scanS} OR
%                          arg.data = {'dose', doseS}
%
%JRA 06/19/06
%
%Usage:
%   dcmobj = export_image_plane_module_field(args)
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
        error('Unsupported data passed to export_image_plane_module.');   
end

switch tag
    %Class 1 Tags -- Required, must have data.
    
    case 2621488    %0028,0030 Pixel Spacing (mm)
        switch type
            case 'scan'
                pixWidth    = scanInfoS.grid1Units;
                pixHeight   = scanInfoS.grid2Units;                
            case 'dose'
                pixWidth    = -doseS.verticalGridInterval;
                pixHeight   = doseS.horizontalGridInterval;                                
        end
        
        %Convert from CERR cm to DICOM mm.        
        data        = [pixWidth pixHeight] * 10;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 2097207    %0020,0037 Image Orientation (Patient)
        data = [1 0 0 0 1 0];
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 2097202    %0020,0032 Image Position (Patient) (mm)
        switch type
            case 'scan'
                xV = scanInfoS.xOffset - ((scanInfoS.sizeOfDimension2-1)*scanInfoS.grid2Units)/2;

                %Invert y,z to match HFS patient coordinates.
                yV = -(scanInfoS.yOffset + ((scanInfoS.sizeOfDimension1-1)*scanInfoS.grid2Units)/2);
                zV = -scanInfoS.zValue;
            case 'dose'
                xV = doseS.coord1OFFirstPoint;
                
                %Invert y,z to match HFS patient coordinates.
                yV = -doseS.coord2OFFirstPoint;
                zV = -doseS.zValues(end);
        end
        
        %Convert from CERR cm to DICOM mm.
        data = [xV yV zV] * 10;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    %Class 2 Tags -- Must be present, can be blank.    
    
    case 1572944    %0018,0050 Slice Thickness (mm)
        switch type
            case 'scan'                
                data = scanInfoS.sliceThickness;
            case 'dose'
                firstZ = doseS.zValues(1);
                lastZ  = doseS.zValues(end);
                numZ   = length(doseS.zValues);      
                relZ   = linspace(firstZ, lastZ, numZ) - firstZ;
                
                if length(relZ) > 1
                    data = relZ(2) - relZ(1);            
                else
                    data = [];
                end
        end
        
        %Convert from CERR cm to DICOM mm.        
        data = data * 10;       
        el = template.get(tag);
        el = ml2dcm_Element(el, data);        
        
    %Class 3 Tags -- presence is optional, currently undefined.
    
    case 2101313    %0020,1041 Slice Location
        
    %Class 1C Tags

    %Class 2C Tags
        
    otherwise
        warning(['No methods exist to populate DICOM image_plane module field ' dec2hex(tag,8) '.']);
end