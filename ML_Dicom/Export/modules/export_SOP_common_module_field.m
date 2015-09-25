function el = export_SOP_commons_module_field(args)
%"export_SOP_commons_module_field"
%   Given a CERR single scan, return a properly populated SOP_Common module tag
%   for use with any Composite Image IOD.  See SOP_common_module_tags.m.
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
%   dcmobj = export_SOP_commons_module_field(args)
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
    case 'scanInfo'
    case 'dose'
    case 'structures'
    otherwise
        error('Unsupported cell type passed to export_SOP_commons_module_field.');                        
end

switch tag
    %Class 1 Tags -- Required, must have data.
    case 524310     %0008,0016 SOP Class UID
        data = structS(1).SOP_Class_UID;                
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
    case 524312     %0008,0018 SOP Instance UID
        data = structS(1).SOP_Instance_UID;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);        
    %Class 2 Tags -- Must be present, can be blank.        

    %Class 3 Tags -- presence is optional, currently undefined.  
    case   524306   %0008,0012 Instance Creation Date
        data = datestr(now, 29);
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case   524307   %0008,0013 Instance Creation Time
        data = datestr(now, 13);
        el = template.get(tag);
        el = ml2dcm_Element(el, data);        
        
    case   524308   %0008,0014 Instance Creator UID
    case   524314   %0008,001A Related GEneral SOP Class UID
    case   524315   %0008,001B Original Specialized SOP Class UID
    case   524560   %0008,0110 Coding Scheme Identification Sequence
    case   524801   %0008,0201 Timezone Offset from UTC
    case  1613825   %0018,A001 Contributing Equipment Sequence
    case  2097171   %0020,0013 Instance Number
    case 16778256   %0100,0410 SOP Instance Status
    case 16778272   %0100,0420 SOP Authorization Date and Time
    case 16778276   %0100,0424 SOP Authorization Comment
    case 16778278   %0100,0426 Authorizaiton Equipment Certification Number        
    case 1342046209 %4FFE,0001 MAC Parameters Sequence
    case 4294639610 %FFFA,FFFA Digital Signatures Sequence

    %Class 1C Tags
    case   524293   %0008,0005 Specific Character Set
    case 67110144   %0400,0500 Encrypted Attributes Sequence
    case  4236176   %0040,A390 HL7 Structured Document Reference Sequence
     
     %Class 2C Tags

    otherwise
        warning(['No methods exist to populate DICOM SOP_common module field ' dec2hex(tag,8) '.']);
end