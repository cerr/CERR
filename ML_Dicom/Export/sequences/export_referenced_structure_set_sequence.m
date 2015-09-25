function el = export_referenced_structure_set_sequence(args)
%"export_referenced_structure_set_sequence"
%   Subfunction to handle referenced_structure_set sequences within the
%   rt_dvh module.  Uses the same layout and principle as the
%   parent function.
%
%   This function takes a CERR DVHs element.
%
%JRA 07/10/06
%
%Usage:
%   @export_referenced_structure_set_sequence(args)
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
DVHS        = args.data{1};
template    = args.template;

switch tag
    case 528720     %0008,1150  Referneced SOP Class UID
        data = DVHS.Referenced_Structure_Set_SOP_Class_UID;
        el = template.get(tag);   
        el = ml2dcm_Element(el, data);        
        
    case 528725     %0008,1155  Referenced SOP Instance UID
        data = DVHS.Referenced_Structure_Set_SOP_Instance_UID;
        el = template.get(tag);   
        el = ml2dcm_Element(el, data);        
        
    otherwise
        warning(['No methods exist to populate DICOM ROI_contour module''s ROI_contour_sequence field: ' dec2hex(tag,8) '.']);
end