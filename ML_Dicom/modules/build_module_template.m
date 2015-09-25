function dcmobj = build_module_template(moduleName)
%"build_module_template"
%   Create a Java DICOM object containing fields used to represent the
%   specified module.
%
%   Valid moduleNames are currently 'patient' 
%
%JRA 06/06/06
%
%Usage:
%   dcmobj = general_equipment_module_template;
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

%Create a dcmobj to hold the structure and data.
dcmobj = org.dcm4che2.data.BasicDicomObject;

Done = 0;

switch lower(moduleName)
    %Get the top level tags used in this module.
    case 'patient'
        tagS = patient_module_tags;
    case 'general_study'
        tagS = general_study_module_tags;
    case 'general_series'
        tagS = general_series_module_tags;
    case 'frame_of_reference'
        tagS = frame_of_reference_module_tags;
    case 'general_equipment'
        tagS = general_equipment_module_tags;
    case 'general_image'
        tagS = general_image_module_tags;
    case 'image_plane'
        tagS = image_plane_module_tags;
    case 'image_pixel'
        tagS = image_pixel_module_tags;
    case 'ct_image'
        tagS = CT_image_module_tags;
    case 'mr_image'
        tagS = MR_image_module_tags;
    case 'sop_common'
        tagS = SOP_common_module_tags;
    case 'structure_set'
        tagS = structure_set_module_tags;
    case 'roi_contour'
        tagS = ROI_contour_module_tags;
    case 'rt_series'
        tagS = RT_series_module_tags;
    case 'rt_roi_observations'
        tagS = RT_ROI_observations_module_tags;
    case 'rt_dose'
        tagS = RT_dose_module_tags;        
    case 'rt_dvh'
        tagS = RT_DVH_module_tags;        
    case 'multi_frame'
        tagS = multi_frame_module_tags;
    otherwise
        error('Unrecognized or unsupported module template requested.')
end


%Create all top level tags in this object.
dcmobj = createEmptyFields(dcmobj, tagS);