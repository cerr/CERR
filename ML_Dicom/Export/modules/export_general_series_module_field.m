function el = export_general_series_module_field(args)
%"export_general_series_module_field"
%   Given a single scan, return a properly populated general_series module tag
%   for use with any Composite Image IOD.  See general_series_module_tags.m.
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
%   This function requires arg.data = {scanS};
%
%JRA 06/19/06
%NAV 07/19/16 updated to dcm4che3
%   replaced ml2dcm_Element to data2dcmElement
%AI 10/24/19 Use imageOrientationPatient to determine patient position
%
%Usage:
%   dcmobj = export_general_series_module_field(args)
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
scanS       = args.data{1};
%template    = args.template;

scanInfo = scanS.scanInfo(1);

switch tag
    %Class 1 Tags -- Required, must have data.
    case  524384    %0008,0060 Modality
        data = scanInfo.imageType;
        if strcmpi(data,'CT SCAN')
            data = 'CT';
        elseif strcmpi(data,'MRI')
            data = 'MR';
        elseif strcmpi(data,'GSPS')
            data = 'PR';
        end
        el = data2dcmElement(data, tag);
        
    case 2097166    %0020,000E Series Instance UID
        data = scanS.Series_Instance_UID;
        el = data2dcmElement(data, tag);

    %Class 2 Tags -- Must be present, can be blank.
    case 2097169    %0020,0011 Series Number

        %el = org.dcm4che3.data.Attributes;
        %el.setString(tag, template.getVR(tag), template.getString(tag));
        data = [];
        el = data2dcmElement(data, tag);
     
    %Class 3 Tags -- presence is optional    
    case  524321    %0008,0021 Series Date

        try
            data = scanS(1).scanInfo(1).DICOMHeaders.SeriesDate;
        catch
            data = [];
        end
        el = data2dcmElement(data, tag);
                
        %Class 3 Tags -- presence is optional
    case  528446    %0008,103E Series Description
        data = scanInfo.seriesDescription;
        %el = template.get(tag);
        %el = ml2dcm_Element(el, data);
        el = data2dcmElement(data, tag);
        
        %Class 3 Tags -- presence is optional, currently undefined.
    case  524337    %0008,0031 Series Time
    case  528464    %0008,1050 Performing Physician's Name
    case  528466    %0008,1052 Performing Physican Identification Number
    case 1577008    %0018,1030 Protocol Name
    case  528496    %0008,1070 Operator's Name
    case  528498    %0008,1072 Operator Identification Sequence
    case  528657    %0008,1111 Referenced Performed Procedure Step Sequence
    case  528976    %0008,1250 Related Series Sequence
    case 1572885    %0018,0015 Body Part Examined
    case 2621704    %0028,0108 Smallest Pixel Value in Series
    case 2621705    %0028,0109 Largest Pixel Value in Series
    case 4194933    %0040,0275 Request Attributes Sequence
    case 4194899    %0040,0253 Performed Procedure Step ID
    case 4194884    %0040,0244 Performed Procedure Step Start Date
    case 4194885    %0040,0245 Performed Procedure Step Start Time
    case 4194900    %0040,0254 Performed Procedure Step Desecription
    case 4194912    %0040,0260 Performed Protocol Code Sequence
    case 4194944    %0040,0280 Comments on the Performed Procedure Step
     
    %Class 1C Tags

    %Class 2C Tags
    case 2097248    %0020,0060 Laterality
    case 1593600    %0018,5100 Patient Position
        %This field is required for CT and MR images.
        try
            
            data = scanInfo.patientPosition;
            el = data2dcmElement(data, tag);
            
        catch
            warning('scanInfo does not contain Patient Position information. Defaulting to HFS');
            data = 'HFS';
            el = data2dcmElement(data, tag);
        end
                   
    otherwise
        warning(['No methods exist to populate DICOM general series module field ' dec2hex(tag,8) '.']);
end