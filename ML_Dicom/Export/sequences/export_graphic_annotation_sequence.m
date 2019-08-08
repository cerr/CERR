function el = export_graphic_annotation_sequence(args)
%"export_graphic_annotation_sequence"
%   Subfunction to handle graphic annotation sequence. 
%   Uses the same layout and principle as the parent function.
%
%   This function takes a CERR GSPS element and the index of that
%   element within the planC.GSPS array.
%
%JRA 06/23/06
%NAV 07/19/16 updated to dcm4che3
%   replaced ml2dcm_Element to data2dcmElement
%
%Usage:
%   @export_graphic_annotation_sequence(args)
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
scanInfoS   = args.data{2};
template    = args.template;

switch tag
    case 528704  %0008,1140  Referenced Image Sequence

        templateEl  = template.getValue(tag);
        fHandle = @export_referenced_image_sequence;        
        
        %New null sequence
        tmp = org.dcm4che3.data.Attributes;
        el = tmp.newSequence(tag, 0);
        
        i = 1; % only one layer
        dcmobj = export_sequence(fHandle, templateEl, {scanInfoS});
        el.add(i-1, dcmobj);
        
        %get attribute to return
        el = el.getParent();
        
    case 7340034  %0070,0002  Graphic layer
        
        graphicLayer = gspsS.presentLabel; % must be the same name used inthe graphic layer sequence
        el = data2dcmElement(el, graphicLayer, tag);        
        
    case 7340040  %0070,0008  Text object sequence

        templateEl  = template.getValue(tag);
        fHandle = @export_text_object_sequence;
        
        %New null sequence
        tmp = org.dcm4che3.data.Attributes;
        el = tmp.newSequence(tag, 0);

        textAnnotationS = gspsS.textAnnotationS;
        nAnnot = length(textAnnotationS);
        
        for i=1:nAnnot
            dcmobj = export_sequence(fHandle, templateEl, {textAnnotationS(i)});
            %dcmobj = export_sequence(fHandle, tag, {structS(i), i});
            el.add(i-1, dcmobj);
        end                      
        %get attribute to return
        el = el.getParent();
        
    case 7340041  %0070,0009  Graphic object sequence

        templateEl  = template.getValue(tag);
        fHandle = @export_graphic_object_sequence;
        
        %New null sequence
        tmp = org.dcm4che3.data.Attributes;
        el = tmp.newSequence(tag, 0);

        graphicAnnotationS = gspsS.graphicAnnotationS;
        nAnnot = length(graphicAnnotationS);
        
        for i=1:nAnnot
            dcmobj = export_sequence(fHandle, templateEl, {graphicAnnotationS(i)});
            %dcmobj = export_sequence(fHandle, tag, {structS(i), i});
            el.add(i-1, dcmobj);
        end                      
        %get attribute to return
        el = el.getParent();
     
   
    otherwise
        warning(['No methods exist to populate DICOM structure_set module''s structure_set_ROI sequence field: ' dec2hex(tag,8) '.']);
end