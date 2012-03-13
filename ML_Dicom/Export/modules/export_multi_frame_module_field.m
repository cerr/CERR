function el = export_multi_frame_module_field(args)
%"export_multi_frame_module_field"
%   Given a single dose and a tag in the multiframe module, return a 
%   properly populated and formatted instance of that tag.  
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
%   This function requires arg.data is a single doseS.
%
%JRA 06/19/06
%
%Usage:
%   dcmobj = export_multi_frame_module_field(args)
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
    case 2621448    %0028,0008  Number of Frames
        switch type
            case 'dose'
                data = length(dataS.zValues);                
        end
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 2621449    %0028,0009  Frame Increment Pointer                       
        switch type
            case 'dose'
                data = '3004000C'; %CERR exports this data in "Grid Frame Offset Vector" (3004, 000C).
        end
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    otherwise
        warning(['No methods exist to populate DICOM rt_dose module field ' dec2hex(tag,8) '.']);
end


