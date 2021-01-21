function el = export_text_object_sequence(args)
%Subfunction to handle text_object sequences within the
%gsps module.  Uses the same layout and principle as the parent
%function.
%
%   This function takes a graphicObject object.
%
%APA 07/26/2019
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
textObjectS         = args.data{1};
template            = args.template;

switch tag
    case 7340035     %0070,0003  Bounding Box Annotation Units
        data = textObjectS.boundingBoxAnnotationUnits;     
        el = data2dcmElement(data, tag);
        
    case 7340036     %0070,0004  Anchor Point Annotation Units
        data = textObjectS.anchorPtAnnotationUnits;        
        el = data2dcmElement(data, tag);
        
    case 7340038     %00700006  Unformatted Text Value
        data = textObjectS.unformattedTextValue;        
        el = data2dcmElement(data, tag);

    case 7340048     %00700010  Bounding Box Top Left Hand Corner
        data = textObjectS.boundingBoxTopLeftHandCornerPt;        
        el = data2dcmElement(data, tag);

    case 7340049     %00700011  Bounding Box Bottom Right Hand Corner
        data = textObjectS.boundingBoxBottomRightHandCornerPt;        
        el = data2dcmElement(data, tag);
        
    case 7340050     %00700012  Bounding Box Text Horizontal Justification
        data = textObjectS.boundingBoxTextHorizontalJustification;        
        el = data2dcmElement(data, tag);
       
    case 7340052     %00700014  Anchor Point
        data = textObjectS.anchorPoint;        
        el = data2dcmElement(data, tag);

    case 7340053     %00700015  Anchor Point Visibility
        data = textObjectS.anchorPointVisibility;        
        el = data2dcmElement(data, tag);

    otherwise
        warning(['No methods exist to populate DICOM GSPS module''s graphic_object_sequence field ' dec2hex(tag,8) '.']);
end