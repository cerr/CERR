function el = export_DVH_referenced_ROI_sequence(args)
%"export_DVH_referenced_ROI_sequence"
%   Subfunction to handle DVH_referenced_ROI sequences within the
%   rt_dvh module.  Uses the same layout and principle as the
%   parent function.
%
%   This function takes a CERR DVHs element.
%
%JRA 07/10/06
%
%Usage:
%   @export_DVH_referenced_ROI_sequence(args)
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
%     case 805699716  %3006,0084  Referenced ROI Number
        %Until UIDs are implemented in CERR this field must be left blank.
        %CERR does not currently explicitly identify the structure used to
        %calculate the DVH.
        
    case 805568610  %3004,0062  DVH ROI Contribution Type
        data = 'INCLUDED';
        el = template.get(tag);
        el = ml2dcm_Element(el, data);  
        
    otherwise
        warning(['No methods exist to populate DICOM RT Dose module''s DVH_referenced_ROI sequence field: ' dec2hex(tag,8) '.']);
end