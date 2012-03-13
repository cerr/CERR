function el = export_general_image_module_field(args)
%"export_general_image_module_field"
%   Given a single scan, return a properly populated general_image module tag
%   for use with any Composite Image IOD.  See general_image_module_tags.m.
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
%   This function requires arg.data = {'scanInfo', scanInfoS} OR
%                          arg.data = {'dose', doseS}
%
%JRA 06/19/06
%
%Usage:
%   dcmobj = export_general_image_module_field(args)
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
dataS       = args.data{2};
template    = args.template;

switch tag
    %Class 1 Tags -- Required, must have data.

    %Class 2 Tags -- Must be present, can be blank.
    case 2097171    %0020,0013 Instance Number
        switch type
            case 'scan'
                data = dataS.imageNumber;
            case 'dose'
                data = dataS.doseNumber;
                if isempty(data)
                    data = 1;
                end
        end
        el = template.get(tag);
        el = ml2dcm_Element(el, data);

        %Class 3 Tags -- presence is optional, currently undefined.
    case  524296    %0008,0008 Image Type
    case 2097170    %0020,0012 Acquisition Number
    case  524322    %0008,0022 Acquisition Date
    case  524338    %0008,0032 Acquisition Time
    case  524330    %0008,002A Acquisition Datetime
    case  528704    %0008,1140 Referenced Image Sequence
    case  532753    %0008,2111 Derivation Description
    case  561685    %0008,9215 Derivation Code Sequence
    case  532754    %0008,2112 Source Image Sequence
    case  528714    %0008,114A Referenced Instance Sequence
    case 2101250    %0020,1002 Images in Acquisition
    case 2113536    %0020,4000 Image Comments
    case 2622208    %0028,0300 Quality Control Image
    case 2622209    %0028,0301 Burned in Annotation
    case 2629904    %0028,2110 Lossy Image Compression
    case 2629906    %0028,2122 Lossy Image Comperssion Ratio
    case 2629908    %0028,2114 Lossy Image Compression Method
    case 8913408    %0088,0200 Icon Image Sequence
    case 542113824  %2050,0020 Presentation LUT Shape
    case 536592     %0008,3010 Irradiation Event UID

        %Class 1C Tags

        %Class 2C Tags
    case 2097184    %0020,0020 Patient Orientation
    case  524323    %0008,0023 Content Date
    case  524339    %0008,0033 Content Time

    otherwise
        warning(['No methods exist to populate DICOM general_image module field ' dec2hex(tag,8) '.']);
end