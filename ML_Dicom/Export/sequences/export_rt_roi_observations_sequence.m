function el = export_rt_roi_observations_sequence(args)
%"export_rt_roi_observations_sequence"
%   Subfunction to handle rt_roi_observation sequences within the
%   rt_roi_observations module.  Uses the same layout and principle as the
%   parent function.
%
%   This function takes a CERR structure element and the index of that
%   element within the planC.structures array.
%
%JRA 06/23/06
%
%Usage:
%   @export_rt_roi_observations_sequence(args)
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
    case 805699714  %3006,0082  Observation Number
        data = index;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 805699716  %3006,0084  Referenced ROI Number
        data = index;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 805699717  %3006,0085  ROI Observation Label
        data = structS.structureName;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);        
        
    case 805699720  %3006,0088  ROI Observation Description
        %Currently Unsupported.
        
    case 805699632  %3006,0030  RT Related ROI Sequence
        %Currently Unsupported.        
        
    case 805699718  %3006,0086  RT ROI Identification Code Sequence
        %Currently Unsupported.                
        
    case 805699744  %3006,00A0  Related RT ROI Observations Sequence
        %Currently Unsupported.                
        
    case 805699748  %3006,00A4  RT ROI Interpreted Type
        el = template.get(tag);
        
    case 805699750  %3006,00A6  ROI Interpreter
        el = template.get(tag);        
        
    case 805961953  %300A,00E1  Material ID
        %Currently Unsupported.        
        
    case 805699760  %3006,00B0  ROI Physical Properties Sequence          
        %Currently Unsupported.
        
    otherwise
        warning(['No methods exist to populate DICOM ROI_contour module''s ROI_contour_sequence field: ' dec2hex(tag,8) '.']);
end