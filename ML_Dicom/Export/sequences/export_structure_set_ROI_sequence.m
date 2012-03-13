function el = export_structure_set_ROI_sequence(args)
%"export_structure_set_ROI_sequence"
%   Subfunction to handle structure_set_ROI sequences within the
%   structure_set module.  Uses the same layout and principle as the parent
%   function.
%
%   This function takes a CERR structure element and the index of that
%   element within the planC.structures array.
%
%JRA 06/23/06
%
%Usage:
%   @export_structure_set_ROI_sequence(args)
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
structS     = args.data{1};
index       = args.data{2};
template    = args.template;

switch tag
    case 805699618  %3006,0020  ROI Number
        data = index;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 805699620  %3006,0024  Referenced Frame of Reference UID
        UID = structS.Frame_Of_Reference_UID;
        el = template.get(tag);
        el = ml2dcm_Element(el, UID);      
        
    case 805699622  %3006,0026  ROI Name
        data = structS.structureName;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);      
        
    case 805699624  %3006,0028  ROI Description
        %Currently unsupported.        
        
    case 805699628  %3006,002C  ROI Volume
        %Currently unsupported.
        
    case 805699638  %3006,0036  ROI Generation Algorithm
        el = template.get(tag);
        
    case 805699640  %3006,0038  ROI Generation Description
        %Currently unsupported.
        
    otherwise
        warning(['No methods exist to populate DICOM structure_set module''s structure_set_ROI sequence field: ' dec2hex(tag,8) '.']);
end