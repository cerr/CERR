function el = export_gsps_module_field(args)
%"export_gsps_module_field"
%   Given a single planC.structures struct and a tag in the ROI_contour
%   module, return a properly populated and formatted instance of
%   that tag.  
%
%   For speed, tag must be a decimal representation of the 8 digit
%   hexidecimal DICOM tag desired, ie instead of '00100010', pass
%   hex2dec('00100010');
%
%   Arguments are passed in a structure, arg:
%       arg.tag         = decimal tag of field to fill
%       arg.data        = CERR structure(s) to fill from
%       arg.template    = an empty template of the module created by the
%                         function build_module_template.m
%
%   This function requires arg.data is a planC.structures.
%
%JRA 06/19/06
%NAV 07/19/16 updated to dcm4che3
%
%Usage:
%   dcmobj = export_roi_contour_module_field(args)
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
gspsS       = args.data{1};
scanS       = args.data{2};
template    = args.template;

switch tag
    %Class 1 Tags -- Required, must have data.    
    case  7340162  %0070,0082 Presentation Creation Date
        data = datestr(now,'yyyymmdd');
        el = data2dcmElement(template, data, tag);
        
    case  7340163   % 0070,0083 Presentation Creation Time 
        data = datestr(now,'hhmmss');
        el = data2dcmElement(template, data, tag);        
        
    case 542113824  % 2050,0020  Presentation LUT Shape 
        data = 'IDENTITY'; % or 'INVERSE'
        el = data2dcmElement(template, data, tag);
        
    case 7340033  %0070,0001 Graphic Annotation Sequence     

        templateEl  = template.getValue(tag);
        fHandle = @export_graphic_annotation_sequence;

        %New null sequence
        tmp = org.dcm4che3.data.Attributes;
        el = tmp.newSequence(tag, 0);
        
        scanSopInstanceUIDc = {scanS.scanInfo.sopInstanceUID};
        
        for i=1:length(gspsS)
            slcNum = strncmp(gspsS(i).referenced_SOP_instance_uid,...
                scanSopInstanceUIDc,length(gspsS(i).referenced_SOP_instance_uid));
            dcmobj = export_sequence(fHandle, templateEl, {gspsS(i),scanS.scanInfo(slcNum)});
            %dcmobj = export_sequence(fHandle, tag, {structS(i), i});
            el.add(i-1, dcmobj);
        end
        %get attribute to return
        el = el.getParent();
        
    case 7340128   %0070,0060 Graphic Layer sequence
        templateEl  = template.getValue(tag);
        fHandle = @export_graphic_layer_sequence;
        
        %New null sequence
        tmp = org.dcm4che3.data.Attributes;
        el = tmp.newSequence(tag, 0);
        
        i = 1; % only 1 graphic layer
        dcmobj = export_sequence(fHandle, templateEl, []);
        el.add(i-1, dcmobj);
        
        %get attribute to return
        el = el.getParent();

    %Class 2 Tags -- Must be present, can be NULL.                
    %Class 3 Tags -- presence is optional, currently undefined.                   
    %Class 1C Tags -- presence is required under special circumstances
    %Class 2C Tags -- presence is required under special circumstances    

    otherwise
        warning(['No methods exist to populate DICOM GSPS module field ' dec2hex(tag,8) '.']);
end