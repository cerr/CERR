function autoContour40SUVMax(structNum)
% autoContour40SUVMax
%
% This function creates a contour at 40% threshold level of Max scan value.
% structNum is the structure index in planC.
%
% Created DK 11/21/06
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


global planC stateS

indexS = planC{end};

scanSet = getStructureAssociatedScan(structNum);

[struct3D slices] = getStruct3DMaskedData(structNum);

siz = size(struct3D);

newStructNum = length(planC{indexS.structures})+ 1;
C = max(struct3D(:));

for i = 1:length(slices)
    slice = struct3D(:,:,i);

    [c I] = max(slice(:));

    if c > (C*4/10)
        [x y]=ind2sub([siz(1) siz(2)],I);

        BW = roicolor(slice,C*4/10,C);

        L = bwlabel(BW, 4);

        region = L(x,y);

        ROI = L == region;
        
        if isempty(find(ROI))
            continue
        end

        [contour, sliceValues] = maskToPoly(ROI, slices(i), scanSet,planC);

        if(length(contour.segments) > 1)
            longestDist = 0;
            longestSeg =  [];

            for j = 1:length(contour.segments)
                segmentV = contour.segments(j).points(:,1:2);
                curveLength = 0;

                for k = 1:size(segmentV,1) - 1
                    curveLength = curveLength + sepsq(segmentV(k,:)', segmentV(k+1,:)');
                end

                if curveLength > longestDist
                    longestDist = curveLength;
                    longestSeg = j;
                end

            end
            tmp = contour.segments(longestSeg).points;

        else
            if isempty(contour.segments.points)
                continue;
            else
                tmp = contour.segments.points;
            end

        end

        planC{indexS.structures}(newStructNum).contour(slices(i)).segments.points = tmp;
    end

end

for l = slices(end)+1 : length(planC{indexS.scan}(scanSet).scanInfo)
    planC{indexS.structures}(newStructNum).contour(l).segments.points = [];
end
stateS.structsChanged = 1;

planC{indexS.structures}(newStructNum).strUID = createUID('structure');
planC{indexS.structures}(newStructNum).assocScanUID = planC{indexS.structures}(structNum).assocScanUID;
planC{indexS.structures}(newStructNum).structureName = [planC{indexS.structures}(structNum).structureName '_40_SUVMax'];

planC = getRasterSegs(planC, newStructNum);

planC = setUniformizedData(planC);