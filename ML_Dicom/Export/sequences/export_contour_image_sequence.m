function el = export_contour_image_sequence(args)
%Subfunction to handle contour_image sequences within the
%structure_set module.  Uses the same layout and principle as the parent
%function.
%
%   This function takes a scanInfo object.
%
%JRA 06/23/06
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
tag                 = args.tag;
scanInfo            = args.data{1};
template            = args.template;

switch tag
    case 528720     %0008,1150  Referenced SOP Class UID
        data = scanInfo.SOP_Class_UID;     
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 528725     %0008,1155  Referenced SOP Instance UID
        data = scanInfo.SOP_Instance_UID;        
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 528736     %0008,1160  Referenced Frame Number
        %Currently not implemented.
       
    otherwise
        warning(['No methods exist to populate DICOM structure_set module''s contour_image_sequence field ' dec2hex(tag,8) '.']);
end