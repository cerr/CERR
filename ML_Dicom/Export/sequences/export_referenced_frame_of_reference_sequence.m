function el = export_referenced_frame_of_reference_sequence(args)
%Subfunction to handle referenced_frame_of_reference sequences within the
%structure_set module.  Uses the same layout and principle as the parent
%function.
%
%   This function takes a list of CERR scans (or scan UIDs if available)
%   and as data to have UIDs created for them.
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
tag         = args.tag;
UID         = args.data{1};
scansS      = args.data{2};
template    = args.template;

switch tag
    %Class 1 Tags -- Required, must have data.
    case 2097234    %0020,0052  Frame of Reference UID
        data = UID;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);

    %Class 3 Tags -- presence is optional, currently undefined.        
    case 805699776  %3006,00C0  Frame of Reference Relationship Sequence       
        %Currently unsupported.
        
    case 805699602  %3006,0012  RT Referenced Study Sequence
        templateEl = template.get(tag);
        fHandle = @export_rt_referenced_study_sequence;

        tmp = org.dcm4che2.data.BasicDicomObject;
        el = tmp.putNull(tag, []);

        %Study Component Management SOP
        StudySOPClassUID = '1.2.840.10008.3.1.2.3.2'; 

        %Find unique study instance UIDs.
        [uniqueStudies,i,j] = unique({scansS.Study_Instance_UID});
        nUniqueStudies = length(uniqueStudies);
        
        for i=1:nUniqueStudies
            scansInStudy = scansS(j == i);
            dcmobj = export_sequence(fHandle, templateEl, {StudySOPClassUID, uniqueStudies(i), scansInStudy});
            el.addDicomObject(i-1, dcmobj);
        end           
        
        
    otherwise
        warning(['No methods exist to populate DICOM structure_set module''s referenced_frame_of_reference_sequence field ' dec2hex(tag,8) '.']);
end