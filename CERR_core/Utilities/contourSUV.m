function planC = contourSUV(structNum,percent,planC)
%function contourSUV(structNum,percent,planC)
%
%This function creates structure at percent% SUV level for structNum
%
%APA,12/15/2006
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

global stateS
if ~exist('planC','var')
    global planC
end
indexS = planC{end};

scanNum                             = getStructureAssociatedScan(structNum,planC);
[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
if isempty(rasterSegments)
    warning('Could not create conotour.')
    return
end
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M                         = double(getScanArray(planC{indexS.scan}(scanNum)));
%%%% reverse data
%maxscan=max(scanArray3M(:));
%scanArray3M =maxscan-scanArray3M;
SUVvals3M                           = mask3M.*scanArray3M(:,:,uniqueSlices);
maxSUVinStruct                      = max(SUVvals3M(:));
cutoff                              = percent/100*maxSUVinStruct;
[xVals, yVals, zVals]               = getScanXYZVals(planC{indexS.scan}(scanNum));
newStructNum                        = length(planC{indexS.structures}) + 1;

newStructS = newCERRStructure(scanNum, planC);
for slcNum = 1:length(uniqueSlices)
    C = contourc(xVals, yVals, SUVvals3M(:,:,slcNum),[cutoff cutoff]);
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

newStructS.structureName    = [planC{indexS.structures}(structNum).structureName 'SUVMax',num2str(percent)];

planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);
planC = getRasterSegs(planC, newStructNum);
planC = updateStructureMatrices(planC, newStructNum, uniqueSlices);

if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && ishandle(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;    
    % Refresh View
    CERRRefresh
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

