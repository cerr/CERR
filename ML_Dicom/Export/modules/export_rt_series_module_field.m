function el = export_rt_series_module_field(args)
%"export_rt_series_module_field"
%   Given a single planC.dose or planC.structures and a tag in the
%   RT_series module, return a properly populated and formatted instance of
%   that tag.  DICOM specifies that RT series also support RT Plan, RT
%   Record, and RT Image, but these are not currently implemented in CERR
%   and so are not required for export.  They may be implemented in the
%   future.
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
%   This function requires arg.data is either a doseS or a structuresS.
%
%JRA 06/19/06
%
%Usage:
%   dcmobj = export_rt_series_module_field(args)
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
structS     = args.data{2};
template    = args.template;

%Check for a supported type.
switch type
    case 'dose'
    case 'structures'
    otherwise
        error('Unsupported modality passed to export_rt_series_module.');                        
end

switch tag
    %Class 1 Tags -- Required, must have data.    

    case  524384    %0008,0060 Modality
        switch type
            case 'dose'
                data = 'RTDOSE';
            case 'structures'
                data = 'RTSTRUCT';
        end
        el = template.get(tag);
        el = ml2dcm_Element(el, data);        
        
    case 2097166    %0020,000E Series Instance UID  
        switch type
            case 'dose'
                UID = structS(1).Series_Instance_UID;
            case 'structures'
                %All structures have the same Series_Instance_UID, simply use first.                
                UID = structS(1).Series_Instance_UID;
        end
        el = template.get(tag);
        el = ml2dcm_Element(el, UID);        
        
    %Class 2 Tags -- Must be present, can be NULL.        

    case 2097169    %0020,0011 Series Number
        el = template.get(tag);        
        
    %Class 3 Tags -- presence is optional, currently undefined.        

    case  528446    %0008,103E Series Description
    case  528657    %0008,1111 Referenced Performed Procedure Step Sequence
    case 4194933    %0040,0275 Request Attributes Sequence
    case 4194899    %0040,0253 Performed Procedure Step ID
    case 4194884    %0040,0244 Performed Procedure Step Start Date
    case 4194885    %0040,0245 Performed Procedure Step Start Time
    case 4194900    %0040,0254 Performed Procedure Step Description
    case 4194912    %0040,0260 Performed Protocol Code Sequence
            
    otherwise
        warning(['No methods exist to populate DICOM rt_series module field ' dec2hex(tag,8) '.']);
end