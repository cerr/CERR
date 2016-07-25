function el = export_rt_referenced_series_sequence(args)
%Subfunction to handle rt_referenced_series sequences within the
%structure_set module.  Uses the same layout and principle as the parent
%function.
%
%   This function takes a SeriesInstanceUID, a scanS.
%
%JRA 06/23/06
%NAV 07/19/16 updated to dcm4che3
%   replaced ml2dcm_Element to data2dcmElement
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
SeriesInstanceUID   = args.data{1};
scanS               = args.data{2};
template            = args.template;

switch tag
    case   2097166  %0020,000E  Series Instance UID
        data = SeriesInstanceUID;

        el = data2dcmElement(template, data, tag);        
        
    case 805699606  %3006,0016  Contour Image Sequence
    %UPDATED to dcm4che3
        %replaced get with getValue
        templateEl = template.getValue(tag);
        fHandle = @export_contour_image_sequence;

        %New empty sequence
        tmp = org.dcm4che3.data.Attributes;
        el = tmp.newSequence(tag, 0);

        %Iterate over each slice.
        for i=1:length(scanS.scanInfo)
            scanInfo = scanS.scanInfo(i);
            
            dcmobj = export_sequence(fHandle, templateEl, {scanInfo});
            el.add(i-1, dcmobj);
        end           
        
        el = el.getParent();
        
    otherwise
        warning(['No methods exist to populate DICOM structure_set module''s rt_referenced_series_sequence field ' dec2hex(tag,8) '.']);
end