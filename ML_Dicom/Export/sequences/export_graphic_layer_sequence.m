function el = export_graphic_layer_sequence(args)
%"export_graphic_layer_sequence"
%   Subfunction to handle structure_set_ROI sequences within the
%   structure_set module.  Uses the same layout and principle as the parent
%   function.
%
%   This function takes a CERR structure element and the index of that
%   element within the planC.structures array.
%
%JRA 06/23/06
%NAV 07/19/16 updated to dcm4che3
%   replaced ml2dcm_Element to data2dcmElement
%
%Usage:
%   @export_structure_set_ROI_sequence(args)
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
template    = args.template;
layerLabel  = args.data{1};
layerOrder  = args.data{2};
layerColor  = args.data{3};

switch tag
    case   7340034  %0070,0002  Graphic Layer
        data = layerLabel;
        el = data2dcmElement(template, data, tag); 
        
    case   7340130  %0070,0062  Graphic Layer Order
        data = layerOrder; % Lower numbered layers are to be rendered first.
        el = data2dcmElement(template, data, tag); 
        
    case   7340134  %0070,0066  Graphic Layer Recommended Display Grayscale Value
        data = 255; %'FFFFH'; % white
        el = data2dcmElement(template, data, tag); 
        
    case   7341057  %0070,0401  Graphic Layer Recommended Display CIELab Value
        data = rgb2lab(layerColor); % cielab color. (this combination results in a shade of orange).
        
        data(1) = data(1)/100*65535;
        data(2) = (100+data(2))/200*65535;
        data(3) = (100+data(3))/200*65535;
        el = data2dcmElement(template, data, tag); 
        
    case   7340136  %0070,0068  Graphic Layer Description
        data = 'RTSTRUCT converted to GSPS using CERR';
        el = data2dcmElement(template, data, tag);         
   
    otherwise
        warning(['No methods exist to populate DICOM graphic_layer module''s graphic_layer sequence field: ' dec2hex(tag,8) '.']);
end