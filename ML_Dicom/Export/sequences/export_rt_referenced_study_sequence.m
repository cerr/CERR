function el = export_RT_referenced_study_sequence(args)
%Subfunction to handle RT_referenced_study sequences within the
%structure_set module.  Uses the same layout and principle as the parent
%function.
%
%   This function takes a StudySOPClassUID, StudyInstanceUID, and scanS.
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
classUID    = args.data{1};
instanceUID = args.data{2};
scansS      = args.data{3};
template    = args.template;

switch tag
    case    528720  %0008,1150  Referenced SOP Class UID
        data = classUID;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case    528725  %0008,1155  Referenced SOP Instance UID
        data = instanceUID;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 805699604  %3006,0014  RT Referenced Series Sequence
        templateEl = template.get(tag);
        fHandle = @export_rt_referenced_series_sequence;

        tmp = org.dcm4che2.data.BasicDicomObject;
        el = tmp.putNull(tag, []);

        %Iterate over each series.
        for i=1:length(scansS)
            SeriesInstanceUID = scansS(i).Series_Instance_UID;
            dcmobj = export_sequence(fHandle, templateEl, {SeriesInstanceUID, scansS(i)});
            el.addDicomObject(i-1, dcmobj);
        end           
        
        
    otherwise
        warning(['No methods exist to populate DICOM structure_set module''s RT_referenced_study_sequence field ' dec2hex(tag,8) '.']);
end