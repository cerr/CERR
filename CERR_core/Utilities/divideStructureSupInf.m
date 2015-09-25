function planC = divideStructureSupInf(structNum,N,planC)
%function planC = divideStructureSupInf(structNum,N,planC)
%
%This function divides the input structure structNum into N-parts
%
%APA, 8/20/2009
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


if ~exist('planC','var')
    global planC
end
indexS = planC{end};

scanNum                             = getStructureAssociatedScan(structNum,planC);
[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
[mask3M, allUniqueSlices]           = rasterToMask(rasterSegments, scanNum,planC);
[xVals, yVals, zVals]               = getScanXYZVals(planC{indexS.scan}(scanNum));
minZ = zVals(allUniqueSlices(1));
maxZ = zVals(allUniqueSlices(end));
deltaZ = (maxZ - minZ)/N;
zStart = minZ;
for i = 1:N
    if i==N
        uniformslicesV = find((zVals >= zStart) & (zVals <= maxZ));
    else
        uniformslicesV = find((zVals >= zStart) & (zVals < zStart + deltaZ));
    end
    sliceIndexV = ismember(allUniqueSlices,uniformslicesV);
    uniqueSlicesIndexC{i} = find(sliceIndexV);
    uniqueSlicesC{i} = allUniqueSlices(sliceIndexV);
    zStart = zStart + deltaZ;
end

structName = planC{indexS.structures}(structNum).structureName;

%Loop over N sets and generate N structures
for newStrNum = 1:N
    uniqueSlices                        = uniqueSlicesC{newStrNum};
    uniqueSlicesIndexV                  = uniqueSlicesIndexC{newStrNum};
    SUVvals3M                           = mask3M(:,:,uniqueSlicesIndexV);
    newStructNum                        = length(planC{indexS.structures}) + 1;

    newStructS = newCERRStructure(scanNum, planC);
    for slcNum = 1:length(uniqueSlices)
        suvM = double(SUVvals3M(end:-1:1,:,slcNum));
        if ~any(suvM(:))
            continue;
        end
        C = contourc(xVals, fliplr(yVals), suvM, [0.5 0.5]);
        indC = getSegIndices(C);
        if ~isempty(indC)
            for seg = 1:length(indC)
                points = [C(:,indC{seg})' zVals(uniqueSlices(slcNum))*ones(length(C(1,indC{seg})),1)];
                newStructS.contour(uniqueSlices(slcNum)).segments(seg).points = points;
            end
        else
            newStructS.contour(uniqueSlices(slcNum)).segments.points = [];
        end
    end

    for l = max(uniqueSlices)+1 : length(planC{indexS.scan}(scanNum).scanInfo)
        newStructS.contour(l).segments.points = [];
    end

    newStructS.structureName    = [structName, '_', num2str(newStrNum)];
    planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);
    planC = getRasterSegs(planC, newStructNum);
    planC = setUniformizedData(planC);

end
if exist('stateS','var')
    stateS.structsChanged = 1;
end

return;


function indC = getSegIndices(C)
% function getSegIndices(C)
%
%This function returns the indices for each segment of input contour C.
%C is output from in-built "contourc" function
%
%APA, 12/15/2006

start = 1;
counter = 1;
indC = [];
while start < length(C(2,:))
    numPts = C(2,start);
    indC{counter} = [(start+1):(start+numPts) start+1];
    start = start + numPts + 1;
    counter = counter + 1;
end

