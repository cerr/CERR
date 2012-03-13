function planC = copyStrToScan_noMesh(structNum,scanNum,planC)
%function planC = copyStrToScan_noMesh(structNum,scanNum,planC)
%
%This function derives a new structure from structNum which is associated
%to scanNum. The naming convention for this new structure is 
%[structName assoc scanNum]. If structNum is already associated to scanNum,
%the unchanged planC is returned back. 
%
%APA, 01/25/08
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

if ~exist('planC')
    global planC
end

indexS = planC{end};

%return if structNum is already associated to scanNum
assocScanNum = getAssociatedScan(planC{indexS.structures}(structNum).assocScanUID);
if assocScanNum == scanNum
    warning(['Structure Number ',num2str(structNum),' is already assocoated with scan ',num2str(scanNum)])
    return;
end

%Get transformation matrix
if ~isfield(planC{indexS.scan}(scanNum),'transM') | isempty(planC{indexS.scan}(scanNum).transM)
    transMnew = eye(4);
else    
    transMnew = planC{indexS.scan}(scanNum).transM;
end
if ~isfield(planC{indexS.scan}(assocScanNum),'transM') | isempty(planC{indexS.scan}(assocScanNum).transM) 
    transMold = eye(4);
else    
    transMold = planC{indexS.scan}(assocScanNum).transM;
end
transM = inv(transMnew)*transMold;

%Get z-coordinates of scan
[jnk1,jnk2,scanZv] = getScanXYZVals(planC{indexS.scan}(scanNum));
[jnk, relStructNum] = getStructureAssociatedScan(structNum, planC);
for i = 1:length(scanZv)
    coord = scanZv(i);
    
    %structUID   = planC{indexS.structures}(structNum).strUID;
    %contourS    = calllib('libMeshContour','getContours',structUID,single(pointOnPlane),single(planeNormal),single([0 1 0]),single([1 0 0]));
    
    [slcC, sliceXVals, sliceYVals] = getStructureSlice(assocScanNum, 3, coord, transM);
    oneStructM = [];
    if relStructNum <= 52
        cellNum = 1;
        if iscell(slcC) && ~isempty(slcC{cellNum})
            oneStructM = bitget(slcC{cellNum}, relStructNum);
        end
    else
        cellNum = ceil((relStructNum-52)/8)+1; %uint8
        if iscell(slcC) && ~isempty(slcC{cellNum})
            oneStructM = bitget(slcC{cellNum}, relStructNum-52-(cellNum-2)*8); %uint8
        end
    end

    if ~isempty(oneStructM)
        C           = contourc(sliceXVals, sliceYVals, double(oneStructM'),[0.5 0.5]);
        indC = getSegIndices(C);
        if ~isempty(indC)
            for seg = 1:length(indC)
                points = [C(:,indC{seg})' coord*ones(length(C(1,indC{seg})),1)];
                contourS(i).segments(seg).points = points;
            end
        else
            contourS(i).segments.points = [];
        end
    else
        contourS(i).segments.points = [];
    end
        
end

strname = [planC{indexS.structures}(structNum).structureName,' asoc ',num2str(scanNum)];

newstr = newCERRStructure(scanNum);
newstr.contour = contourS;
newstr.structureName = strname;
newstr.associatedScan = scanNum;
newstr.assocScanUID = planC{indexS.scan}(scanNum).scanUID;
newstr.meshRep = 0;
numStructs = length(planC{indexS.structures});

%Append new structure to planC.
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newstr, numStructs+1, []);

%Create Raster Segments
planC = getRasterSegs(planC, numStructs+1);

%Update uniformized data.
planC = updateStructureMatrices(planC, numStructs+1);

if isfield(stateS,'handle') && ishandle(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
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

