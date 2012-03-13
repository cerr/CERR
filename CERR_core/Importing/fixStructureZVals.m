function planC = fixStructureZVals(planC)
%Compares zVals stored in structure contours to CT zValues.
%Correct by replacing the structure's zVals with those of
%the CT slice it was contoured on.
%
%We have encountered some archives where the two do not match,
%which causes problems with generating 3D datasets.
%
% JRA 10/24/03
%
% TODO: Vectorize.
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

indexS = planC{end};
ctZVal = [planC{indexS.scan}.scanInfo.zValue];

for structNum=1:length(planC{indexS.structures})
    errorFound = 0;
    errorDiff = [];
    contour = planC{indexS.structures}(structNum).contour;
    for sliceNum=1:length(contour)
        for pointsSet=1:length(contour(sliceNum).segments)
            if ~isempty(contour(sliceNum).segments(pointsSet).points)
                structureZVals = contour(sliceNum).segments(pointsSet).points(:,3);

                uniqStrZvals = unique(structureZVals);
                if length(uniqStrZvals) > 1
                    for uniqInd = 1:length(uniqStrZvals)
                        indZvals = find(structureZVals==uniqStrZvals(uniqInd));
                        numInds(uniqInd) = length(indZvals);
                    end
                    [jnk,maxInd] = max(numInds);

                    uniqStructVal = uniqStrZvals(maxInd);
                    CERRStatusString(['Structure "',planC{indexS.structures}(structNum).structureName,'" has inconsistent contours defined at z = ', num2str(ctZVal(ind)), ' slice location.'])
                    CERRStatusString(['Using the contour points defined at z = ',num2str(uniqStructVal)])
                else
                    uniqStructVal = uniqStrZvals;
                end

                %ind = findnearest(ctZVal, unique(structureZVals));
                ind = findnearest(ctZVal, uniqStructVal);

                wrongZVals = structureZVals ~= ctZVal(ind);

                if find(wrongZVals)
                    errorFound = 1;
                    errorDiff = [errorDiff abs(structureZVals' - ctZVal(ind))];
                    contour(sliceNum).segments(pointsSet).points(find(wrongZVals),3) = ctZVal(ind);
                end
            end
        end
    end
    %Now check for bad rasterSegment zValues, that may have been created in
    %old plans from uncorrected contour data.
    %     for sliceNum=1:length(contour)
    [rasterSegs, planC, isError] = getRasterSegments(structNum, planC);
    %rasterSegs = planC{indexS.structures}(structNum).rasterSegments;
    if ~isempty(rasterSegs)
        if rasterSegs(:,1) ~= [planC{indexS.scan}.scanInfo(rasterSegs(:,6)).zValue]';
            rasterSegs(:,1) = [planC{indexS.scan}.scanInfo(rasterSegs(:,6)).zValue]';
        end
    end
    planC{indexS.structures}(structNum).rasterSegments = rasterSegs;
    %     end

    if errorFound
        CERRStatusString(['Correcting inconsistent zValues in ' planC{indexS.structures}(structNum).structureName '. Median correction is ' num2str(median(errorDiff)) ' cm.']);
        planC{indexS.structures}(structNum).contour = contour;
    end
end
CERRStatusString('');