function el = export_graphic_object_sequence(args)
%Subfunction to handle graphic_object sequences within the
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
graphicObjectS      = args.data{1};
template            = args.template;

switch tag
    case 7340037     %0070,0005  Graphic Annotation Units
        data = graphicObjectS.graphicAnnotationUnits;     
        el = data2dcmElement(template, data, tag);
        
    case 7340064     %0070,0020  Graphic Dimensions
        data = graphicObjectS.graphicAnnotationDims;        
        el = data2dcmElement(template, data, tag);
        
    case 7340065     %0070,0021  Number of Graphic Points
        data = graphicObjectS.graphicAnnotationNumPts;        
        el = data2dcmElement(template, data, tag);

    case 7340066     %0070,0022  Graphic Data
        data = graphicObjectS.graphicAnnotationData;        
        el = data2dcmElement(template, data, tag);

    case 7340067     %0070,0023  Graphic Type
        data = graphicObjectS.graphicAnnotationType;        
        el = data2dcmElement(template, data, tag);
        
    case 7340068     %0070,0024  Graphic Filled
        data = graphicObjectS.graphicAnnotationFilled;        
        el = data2dcmElement(template, data, tag);
       
    otherwise
        warning(['No methods exist to populate DICOM GSPS module''s graphic_object_sequence field ' dec2hex(tag,8) '.']);
end