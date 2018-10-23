function el = export_radiopharmaceutical_info_sequence(args)
%"export_radiopharmaceutical_info_sequence"
%   Subfunction to handle ROI_contour sequences within the ROI_contour
%   module.  Uses the same layout and principle as the parent
%   function.
%
%   This function takes a CERR structure element and the index of that
%   element within the planC.structures array.
%
%JRA 06/23/06
%
%Usage:
%   @export_ROI_contour_sequence(args)
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
scanS     = args.data{1};
template    = args.template;

switch tag
    case 1577074 %0018,1072   Radiopharmaceutical Start Time

        data = scanS.DICOMHeaders.RadiopharmaceuticalInformationSequence...
            .Item_1.RadiopharmaceuticalStartTime;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);

    case 1577076 %0018,1074   Radionuclide Total Dose
        data = scanS.DICOMHeaders.RadiopharmaceuticalInformationSequence...
            .Item_1.RadionuclideTotalDose;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);

    case 1577077 %0018,1075   Radionuclide Half Life
        data = scanS.DICOMHeaders.RadiopharmaceuticalInformationSequence...
            .Item_1.RadionuclideHalfLife;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);

    otherwise
        warning(['No methods exist to populate DICOM PET module''s RadiopharmaceuticalInformationSequence field: ' dec2hex(tag,8) '.']);
end
