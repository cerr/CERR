function [patientobj, studyobj, seriesobj, frameobj, eqobj, imgobj, imgplaneobj, imgpixobj, CTobj, SOPobj] = explode_CT_image_IOD(dcmobj)
%"explode_CT_image_IOD"
%   Split a CT_image_IOD java DICOM object into its component modules.
%
%JRA 06/06/06
%
%Usage:
%   dcmobj = explode_CT_image_IOD(dcmobj)
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

%Get empty Java DICOM representations of each module in the CT IOD.
patient     = build_module_template('patient');
study       = build_module_template('general_study');
series      = build_module_template('general_series');
frame       = build_module_template('frame_of_reference');
equipment   = build_module_template('general_equipment');
genimg      = build_module_template('general_image');
imgplane    = build_module_template('image_plane');
imgpixel    = build_module_template('image_pixel');
CTimg       = build_module_template('CT_image');
SOP         = build_module_template('SOP_common');

%Filter the passed dcmobj by the fields included in each template module.
patientobj  = dcmobj.subSet(patient);
studyobj    = dcmobj.subSet(study);
seriesobj   = dcmobj.subSet(series);
frameobj    = dcmobj.subSet(frame);
eqobj       = dcmobj.subSet(equipment);
imgobj      = dcmobj.subSet(genimg);
imgplaneobj = dcmobj.subSet(imgplane);
imgpixobj   = dcmobj.subSet(imgpixel);
CTobj       = dcmobj.subSet(CTimg);
SOPobj      = dcmobj.subSet(SOP);