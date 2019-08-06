function el = export_referenced_series_sequence(args)
%Subfunction to handle graphic_object sequences within the
%gsps module.  Uses the same layout and principle as the parent
%function.
%
%   This function takes a graphicObject object.
%
%APA 07/31/2019
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
gspsS               = args.data{1};
scanS               = args.data{2};
template            = args.template;

switch tag
    
    case 528704  %0008,1140  Referenced Image Sequence
        templateEl  = template.getValue(tag);
        fHandle = @export_referenced_image_sequence;

        %New null sequence
        tmp = org.dcm4che3.data.Attributes;
        el = tmp.newSequence(tag, 0);
        
        scanSopInstanceUIDc = {scanS.scanInfo.sopInstanceUID};
        
        for i=1:length(gspsS)
            slcNum = strncmp(gspsS(i).referenced_SOP_instance_uid,...
                scanSopInstanceUIDc,length(gspsS(i).referenced_SOP_instance_uid));
            dcmobj = export_sequence(fHandle, templateEl, {scanS.scanInfo(slcNum)});
            el.add(i-1, dcmobj);
        end
        %get attribute to return
        el = el.getParent();
    
    case 2097166 %0020,000E  Series Instance UID
        el = data2dcmElement(template, scanS.Series_Instance_UID, tag);
    
    otherwise
        warning(['No methods exist to populate DICOM GSPS module''s export_displayed_area_selection_sequence field ' dec2hex(tag,8) '.']);
end