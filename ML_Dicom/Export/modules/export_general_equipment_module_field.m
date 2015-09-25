function el = export_general_equipment_module_field(args)
%"export_general_equipment_module_field"
%   Given a single scan, return a properly populated general_equipment module tag
%   for use with any Composite Image IOD.  See general_requipment_module_tags.m.
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
%   This function requires arg.data = {scanS}, {structuresS}, or {doseS}.
%
%JRA 06/19/06
%
%Usage:
%   dcmobj = export_general_equipment_module_field(args)
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
type        = args.data{1};
structS     = args.data{2};
template    = args.template;

%Check for a supported type.
switch type
    case 'scan'
        scanInfo = structS.scanInfo(1);
    case 'structures'
    case 'dose'
    otherwise
        error('Unsupported modality passed to export_general_equipment_module_field.');                        
end

switch tag
    %Class 1 Tags -- Required, must have data.

    %Class 2 Tags -- Must be present, can be blank.     
    case  524400    %0008,0070 Manufacturer
        switch type
            case 'scan'
                try
                    data = scanInfo.scannerType;
                catch
                    data = 'CERR';
                end
            case 'structures'
                data = 'CERR';
            case 'dose'
                data = 'CERR';
        end
        el = template.get(tag);   
        el = ml2dcm_Element(el, data);
        
    %Class 3 Tags -- presence is optional, currently undefined.
    case  524416    %0008,0080 Institution Name
        data = 'CERR';
        el = template.get(tag);   
        el = ml2dcm_Element(el, data);
    case  524417    %0008,0081 Institution Address        
    case  528400    %0008,1010 Station Name
        data = 'CERR';
        el = template.get(tag);   
        el = ml2dcm_Element(el, data);
        
    case  528448    %0008,1040 Institutional Department Name
    case  528528    %0008,1090 Manufacturer's Model Name
        data = 'CERR';
        el = template.get(tag);   
        el = ml2dcm_Element(el, data);        
    case 1576960    %0018,1000 Device Serial Number
    case 1576992    %0018,1020 Software Versions
    case 1577040    %0018,1050 Spatial Resolution
    case 1577472    %0018,1200 Date of Last Calibration
    case 1577473    %0018,1201 Time of Last Calibration
    case 2621728    %0028,0120 Pixel Padding Value
    otherwise
        warning(['No methods exist to populate DICOM general_equipment module field ' dec2hex(tag,8) '.']);
end