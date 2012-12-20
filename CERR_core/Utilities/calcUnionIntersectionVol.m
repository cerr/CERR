function [unionVolume,intersectVolume] = calcUnionIntersectionVol(structNumV,planC)
%function planC = calcUnionIntersectionVol(structNumV,planC)
%
%This function calculates volume of union and intersection from structNumV.
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

scanNum = getStructureAssociatedScan(structNumV(1));
structureC{1} = getUniformStr(structNumV(1));
%Get z-coordinates of scan
[scanXv,scanYv,scanZv] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
[numRows,numCols,numSlcs] = size(structureC{1});
zeroSlcM = zeros(numRows,numCols,'uint8');

for strInd = 2:length(structNumV)

    structNum = structNumV(strInd);

    %return if structNum is already associated to scanNum
    assocScanNum = getAssociatedScan(planC{indexS.structures}(structNum).assocScanUID);

    if scanNum ~= assocScanNum
        struct3M = [];

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

        [jnk, relStructNum] = getStructureAssociatedScan(structNum, planC);
        
        h = waitbar(0,'Interpolating scan...');
        
        for i = 1:length(scanZv)
            coord = scanZv(i);

            %structUID   = planC{indexS.structures}(structNum).strUID;
            %contourS    = calllib('libMeshContour','getContours',structUID,single(pointOnPlane),single(planeNormal),single([0 1 0]),single([1 0 0]));

            [slc, sliceXVals, sliceYVals] = getStructureSlice(assocScanNum, 3, coord, transM);
            if (length(sliceXVals) ~= numCols) || (length(sliceYVals) ~= numRows)
                error('Associated scans have different size')
            end
            oneStructM  = double(bitget(slc, relStructNum));
            if ~isempty(oneStructM)
                struct3M(:,:,i) = oneStructM';
            else
                struct3M(:,:,i) = zeroSlcM;
            end
            waitbar(i/length(scanZv),h)

        end
        close(h)
        structureC{strInd} = struct3M;

    else % structure associated to same base scan
        
        structureC{strInd} = getUniformStr(structNum);
        
    end

end

combineStr3M = structureC{1};
for i=2:length(structureC)
    combineStr3M = combineStr3M + structureC{i};
end
intersectStr3M = combineStr3M==length(structureC);
unionStr3M = combineStr3M>0;

dx = abs(scanXv(1)-scanXv(2));
dy = abs(scanYv(1)-scanYv(2));
dz = abs(scanZv(1)-scanZv(2));

unionVolume = length(find(unionStr3M)) * dx*dy*dz;
intersectVolume = length(find(intersectStr3M)) * dx*dy*dz;

nameStr = '';
for i=1:length(structNumV)
    nameStr = [nameStr , ', ', planC{indexS.structures}(structNumV(i)).structureName];
end
nameStr(1) = [];
nameStr = ['Structures:', nameStr];

CERRStatusString('----------------------------------------------------------','console')
CERRStatusString(nameStr,'console')
CERRStatusString(['Volume of Union = ',num2str(unionVolume),' cc'],'console')
CERRStatusString(['Volume of Intersection = ',num2str(intersectVolume), ' cc'],'console')
CERRStatusString(['Intersection/Union = ',num2str(intersectVolume/unionVolume)],'console')
CERRStatusString('----------------------------------------------------------','console')
CERRStatusString(['Intrsc = ',num2str(intersectVolume), ',  Union = ',num2str(unionVolume), ' cc'],'gui')

return;

