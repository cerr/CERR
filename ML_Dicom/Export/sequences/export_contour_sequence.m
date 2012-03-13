function el = export_contour_sequence(args)
%"export_contour_sequence"
%   Subfunction to handle contour sequences within the ROI_contour
%   module.  Uses the same layout and principle as the parent
%   function.
%
%   This function takes a single CERR contour, Nx3, as args.data
%
%JRA 06/23/06
%
%Usage:
%   @export_contour_sequence(args)
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
contour     = args.data{1};
template    = args.template;

switch tag
    case 805699656  %3006,0048  Contour Number
        %Currently unsupported.
        
    case 805699657  %3006,0049  Attached Contours
        %Currently unsupported.
        
    case 805699606  %3006,0016  Contour Image Sequence
        %Currently unsupported.
        
    case 805699650  %3006,0042  Contour Geometric Type
        data = 'CLOSED_PLANAR'; %All CERR contours are currently closed planar
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
                
    case 805699652  %3006,0044  Contour Slab Thickness
        %Currently unsupported.
        
    case 805699653  %3006,0045  Contour Offset Vector
        %Currently unsupported.
        
    case 805699654  %3006,0046  Number of Contour Points
        data = size(contour,1);
        
        %Take into account the deletion of last point that will occur in
        %the Contour Data routine if first/last points are duplicates.
        if contour(1,:) == contour(end,:) & size(contour, 1) > 1
           data = data - 1;
        end
        el = template.get(tag);
        el = ml2dcm_Element(el, data(:));        

    case 805699664  %3006,0050  Contour Data
        %Convert from CERR cm to DICOM mm.
        contour = contour * 10;
        
        %Convert from CERR coordinates to DICOM patient orientation
        %coordinates.  Currently assuming HFS orientation.
        contour(:,2) = -contour(:,2);
        contour(:,3) = -contour(:,3);
        
        %Check for first/last points being the same.  If the same, remove
        %one as specified by DICOM's closed contour definition.
        if contour(1,:) == contour(end,:) & size(contour, 1) > 1
           contour(end,:) = [] ;
        end
        
        data = contour'; %Transpose and use (:) operator to get linear x,y,z,x,y,z,x,... pattern.
        el = template.get(tag);
        el = ml2dcm_Element(el, data(:));        
    otherwise
        warning(['No methods exist to populate DICOM ROI_contour module''s contour_sequence field: ' dec2hex(tag,8) '.']);
end