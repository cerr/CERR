function dcmobj = export_module(moduleName, varargin)
%"export_module"
%   Returns a populated Java dcmobj representing a requested module,
%   given its moduleName string and the data required to populate the
%   fields.
%
%   Currently supported module names and their parameters are:
%       'patient'               scanS
%       'general_study'         scanS
%       'general_series'        scanS, doseS, structureS
%       'frame_of_reference'    scanS
%       'general_equipment'     'scan', scanS
%                               'structures', structureS
%       'general_image'         scanInfoS, scanS
%       'image_plane'           scanInfoS, scanS
%       'image_pixel'           scanInfoS, scanS
%       'ct_image'              scanInfoS, scanS
%       'sop_common'            'scan', scanS 
%                               'structures', structureS
%       'structure_set'         structureS
%       'roi_contour'           structureS
%       'rt_series'             'structure', structureS
%       'rt_roi_observations'   structureS
%       'rt_dose'               
%       'rt_dvh'                
%
%JRA 06/19/06
%
%Usage:
%   dcmobj = export_module(moduleName, varargin)
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

dcmobj = org.dcm4che2.data.BasicDicomObject;

switch lower(moduleName)
    %Get the top level tags used in this module.
    case 'patient'
        tagS = patient_module_tags;
        export_function = @export_patient_module_field;
    case 'general_study'
        tagS = general_study_module_tags;
        export_function = @export_general_study_module_field;        
    case 'general_series'
        tagS = general_series_module_tags;
        export_function = @export_general_series_module_field;        
    case 'frame_of_reference'
        tagS = frame_of_reference_module_tags;
        export_function = @export_frame_of_reference_module_field;        
    case 'general_equipment'
        tagS = general_equipment_module_tags;
        export_function = @export_general_equipment_module_field;        
    case 'general_image'
        tagS = general_image_module_tags;
        export_function = @export_general_image_module_field;        
    case 'image_plane'
        tagS = image_plane_module_tags;
        export_function = @export_image_plane_module_field;        
    case 'image_pixel'
        tagS = image_pixel_module_tags;
        export_function = @export_image_pixel_module_field;        
    case 'ct_image'
        tagS = CT_image_module_tags;
        export_function = @export_CT_image_module_field;  
    case 'mr_image'
        tagS = MR_image_module_tags;
        export_function = @export_MR_image_module_field;  
    case 'sop_common'
        tagS = SOP_common_module_tags;
        export_function = @export_SOP_common_module_field;          
    case 'structure_set'
        tagS = structure_set_module_tags;
        export_function = @export_structure_set_module_field;
    case 'roi_contour'
        tagS = ROI_contour_module_tags;
        export_function = @export_roi_contour_module_field;
    case 'rt_series'
        tagS = RT_series_module_tags;
        export_function = @export_rt_series_module_field;
    case 'rt_roi_observations'
        tagS = RT_ROI_observations_module_tags;
        export_function = @export_rt_roi_observations_module_field;        
    case 'rt_dose'
        tagS = RT_dose_module_tags;
        export_function = @export_rt_dose_module_field;        
    case 'rt_dvh'
        tagS = RT_DVH_module_tags;
        export_function = @export_RT_DVH_module_field;        
    case 'multi_frame'
        tagS = multi_frame_module_tags;
        export_function = @export_multi_frame_module_field;
    otherwise
        error('Unrecognized or unsupported module export requested.')
end

%Prepare a dcmobj template to be used by the export function for blank
%elements.
template = build_module_template(moduleName);

%Convert top level tags to decimal form.
allTags = hex2dec({tagS.tag});

%Iterate over all tags, calling the appropriate export function.
for i=1:length(allTags)
    
   %Prepare argments struct to pass to export function.
   args = [];
   args.tag         = allTags(i);
   args.data        = varargin;
   args.template    = template;
   
   %Get the SimpleDicomElement Java object with data properly filled.
   %In this line "export_function" is a function HANDLE not an actual
   %function.  Need to check backwards compatibility with previous ML vers.
   el = export_function(args);
   
   if ~isempty(el)
       dcmobj.add(el);
   else       
       %Data in planC was insufficent to construct this element.
   end
end