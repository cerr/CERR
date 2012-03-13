function downSampleScan(numRows,numCols)
%function planC = downSampleScan(planC)
%This function downsdamples scan within planC (planC must be global).
%INPUT: numRows: Number of rows desired in scanArray
%       numCols: Number of columns desired in scanArray
%
%APA, 9/15/2006
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

global planC
indexS = planC{end};
scanS = planC{indexS.scan};
[xVals, yVals, zVals] = getScanXYZVals(scanS);
xValsDown = linspace(xVals(1),xVals(end),numCols);
yValsDown = linspace(yVals(1),yVals(end),numRows);
newGridInterval2 = xValsDown(2) - xValsDown(1);
newGridInterval1 = yValsDown(1) - yValsDown(2);

%downsample scan
h = waitbar(0,'Reinterpolating scan...');
for j=1:length(planC{indexS.scan}(1).scanInfo)

    waitbar(j/length(planC{indexS.scan}(1).scanInfo),h);

    sI = planC{indexS.scan}(1).scanInfo(j);
    slc = planC{indexS.scan}(1).scanArray(:,:,j);

    CTDatatype = class(slc);

    [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(1), j);

    sI.grid1Units = newGridInterval1;
    sI.grid2Units = newGridInterval2;
    sI.sizeOfDimension1 = numRows;
    sI.sizeOfDimension2 = numCols;
    planC{indexS.scan}(1).scanInfo(j) = sI;

    newSlc = finterp2(xV, yV, double(slc), xValsDown, yValsDown, 1,0);
    newSlc = reshape(newSlc, [length(yValsDown) length(xValsDown)]);

    switch CTDatatype
        case 'uint8'
            newSlc = uint8(newSlc);
        case 'uint16'
            newSlc = uint16(newSlc);
        case 'uint32'
            newSlc = uint32(newSlc);
        case 'single'
            newSlc = single(newSlc);
    end
    newScanArray(:,:,j) = newSlc;
end
planC{indexS.scan}(1).scanArray = newScanArray;
close(h);

%re-rasterize
for i = 1:length(planC{indexS.structures})
    planC{indexS.structures}(i).rasterSegments = [];
end

% re-uniformize
planC{indexS.scan}.uniformScanInfo = [];
planC{indexS.scan}.scanArraySuperior = [];
planC{indexS.scan}.scanArrayInferior = [];
planC{indexS.structureArray}.indicesArray = [];
planC{indexS.structureArray}.bitsArray = [];
planC{indexS.structureArrayMore}.indicesArray = [];
planC{indexS.structureArrayMore}.bitsArray = [];
planC = setUniformizedData(planC);

%save this new planC
sliceCallback('SAVEASPLANC')
