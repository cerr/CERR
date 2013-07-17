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

scanNum = 1;

global planC
indexS = planC{end};
[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
xValsDown = linspace(xVals(1),xVals(end),numCols);
yValsDown = linspace(yVals(1),yVals(end),numRows);
newGridInterval2 = xValsDown(2) - xValsDown(1);
newGridInterval1 = yValsDown(1) - yValsDown(2);

%downsample scan
h = waitbar(0,'Reinterpolating scan...');
for j=1:length(planC{indexS.scan}(scanNum).scanInfo)

    waitbar(j/length(planC{indexS.scan}(scanNum).scanInfo),h);

    sI = planC{indexS.scan}(scanNum).scanInfo(j);
    slc = planC{indexS.scan}(scanNum).scanArray(:,:,j);

    CTDatatype = class(slc);

    [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanNum), j);

    sI.grid1Units = newGridInterval1;
    sI.grid2Units = newGridInterval2;
    sI.sizeOfDimension1 = numRows;
    sI.sizeOfDimension2 = numCols;
    planC{indexS.scan}(scanNum).scanInfo(j) = sI;

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
planC{indexS.scan}(scanNum).scanArray = newScanArray;
close(h);

planC = reRasterAndUniformize;

%save this new planC
%sliceCallback('SAVEASPLANC')
