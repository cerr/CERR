function el = export_ROI_contour_sequence(args)
%"export_ROI_contour_sequence"
%   Subfunction to handle ROI_contour sequences within the ROI_contour
%   module.  Uses the same layout and principle as the parent
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
%   @export_ROI_contour_sequence(args)
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
structS     = args.data{1};
index       = args.data{2};
template    = args.template;

switch tag
    case 805699716 %3006,0084   Referenced ROI Number

        data = index; %Simply using CERR structS index.
        el = data2dcmElement(template, data, tag);

    case 805699626 %3006,002A   ROI Display Color

        structColor = structColorRescale(structS.structureColor);
        
        el = data2dcmElement(el, structColor, tag);

    case 805699648 %3006,0048   Contour Sequence
        templateEl  = template.getValue(tag);
        fHandle = @export_contour_sequence;

        tmp = org.dcm4che3.data.Attributes;
        el = tmp.newSequence(tag, 0);

        nContours = length(structS.contour);

        numAdded = 0;

        %Iterate over contour slices in this structure.
        for i=1:nContours

            nSegments = length(structS.contour(i).segments);

            %Iterate over segments in this slice.
            for j=1:nSegments

                nPoints = length(structS.contour(i).segments(j).points);

                %If no points, not a real contour.  A CERR artifact.
                if nPoints == 0
                    continue;
                else
                    %A real contour, pass it to export_contour_sequence.

                    %Get points.
                    points = structS.contour(i).segments(j).points;

                    % dcmobj = export_sequence(fHandle, templateEl, {points});
                    dcmobj = export_sequence(fHandle, templateEl, {structS.contour(i), j});
                    el.add(numAdded, dcmobj);

                    numAdded = numAdded + 1;
                end

            end

        end
        
        el = el.getParent();
        
    otherwise
        warning(['No methods exist to populate DICOM ROI_contour module''s ROI_contour_sequence field: ' dec2hex(tag,8) '.']);
end

function structColor = structColorRescale(structColor)

structColor = structColor*255;

structColor = round(structColor);
