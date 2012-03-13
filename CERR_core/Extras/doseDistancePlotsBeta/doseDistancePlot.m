function [dist3M, doses3M, firstRow, lastRow, firstCol, lastCol, firstSlice, lastSlice] = doseDistancePlot(structNum, minDistance, minOrMax, resolution, skinNum, noPlot)
%function doseDistancePlot(structNum, minDistance, resolution, minOrMax)
%Plot dose summary statistics of constant-distance contours, defined as
%contours where each point has the same minimum distance to the surface
%structure.
%structNum - the structure number,
%minDistance - the distance beyond the structure to extend the analysis,
%resolution - the distance resolution in cm of the plot,
%minOrMax - plot the 'min', 'max', or 'mean' value of all points on the
%contour which have the same contour distance.
%noPlot - if present and equal to 1, no plot is produced, and the routine
%returns outputs.
%Example:  doseDistancePlot(3, 2,0.25,'max');
%If the resolution is the empty matrix, the CT resolution is used
%A related function, dist3M = getDistanceXForm, returns the 3-D distance transform,
%giving the distance from each sampled point to the surface.  If the
%resolution is the empty matrix, the CT resolution is used and the returned
%distance transform applies to each CT element.
%
%Latest modifications:  5 May 03, JOD, first version.
%                      13 May 03, JOD, added blank status at end.
%                                      Added extra input (skin structure number) to take away points outside skin.
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

global stateS planC  %Note planC may need to be updated with DSH points.

indexS = planC{end};

noZeroDoseVals = 1;  %Don't include zero dose values in dose distance plot.  This gets rid of problem
                     %with tissue/air interface.
scanNum = getStructureAssociatedScan(structNum);

if ~exist('resolution') | isempty(resolution)
  resolution = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
end

%First get the surface points mask and their positions:
CERRStatusString('Get surface points...')

pointsM = planC{indexS.structures}(structNum).DSHPoints;

if isempty(pointsM)

  %-----Get any dose surface points--------%
  planC = getDSHPoints(planC, stateS.optS, structNum)  
  pointsM = planC{indexS.structures}(structNum).DSHPoints;

end

zSurfV = pointsM(:,3);
ySurfV = pointsM(:,2);
xSurfV = pointsM(:,1);

%[mask3MU, xSurfV, ySurfV, zSurfV] = getStructSurface(structNum, planC);
CERRStatusString('Surface points established.')

CERRStatusString('Getting distance transform...')
%Next get the x, y, and z limits.

x_low = min(xSurfV) - minDistance;
x_high = max(xSurfV) + minDistance;

y_low = min(ySurfV) - minDistance;
y_high = max(ySurfV) + minDistance;

z_low = min(zSurfV) - minDistance;
z_high = max(zSurfV) + minDistance;

%Get corresponding nearest voxels:

sliceNum = 1; %doesn't matter...


[row1, col1] = xytom(x_low, y_low, sliceNum, planC, scanNum);

row1 = round(row1);
col1 = round(col1);

[row2, col2] = xytom(x_low, y_high, sliceNum, planC, scanNum);

row2 = round(row2);
col2 = round(col2);

[row3, col3] = xytom(x_high, y_low, sliceNum, planC, scanNum);

row3 = round(row3);
col3 = round(col3);

[row4, col4] = xytom(x_high, y_high, sliceNum, planC, scanNum);

row4 = round(row4);
col4 = round(col4);

s = planC{indexS.scan}.scanInfo(1).sizeOfDimension1;

rV = clip([row1, row2, row3, row4],1,s,'limits');
cV = clip([col1, col2, col3, col4],1,s,'limits');

%Get z values:
zValues    = [planC{indexS.scan}.scanInfo(:).zValue];

z1 = min(abs(zValues - z_low));
z2 = min(abs(zValues - z_high));

ind1 = find(abs(zValues - z_low) == z1);
ind2 = find(abs(zValues - z_high) == z2);
ind1 = ind1(1);
ind2 = ind2(1);

slice1 = min([ind1,ind2]);
slice2 = max([ind1,ind2]);

firstRow = min(rV);
lastRow  = max(rV);
firstCol = min(cV);
lastCol  = max(cV);
firstSlice = slice1;
lastSlice  = slice2;

%Now get associated x, y, and z points:

%Get corner points:
[x1,y1,z1] = mtoxyz(max(rV),min(cV),slice1,scanNum, planC);
[x2,y2,z2] = mtoxyz(min(rV),min(cV),slice1,scanNum, planC);
[x3,y3,z3] = mtoxyz(min(rV),max(cV),slice1,scanNum, planC);
[x4,y4,z4] = mtoxyz(max(rV),max(cV),slice1,scanNum, planC);

[x5,y5,z5] = mtoxyz(max(rV),min(cV),slice2,scanNum, planC);
[x6,y6,z6] = mtoxyz(min(rV),min(cV),slice2,scanNum, planC);
[x7,y7,z7] = mtoxyz(min(rV),max(cV),slice2,scanNum, planC);
[x8,y8,z8] = mtoxyz(max(rV),max(cV),slice2,scanNum, planC);

%Get delta's
delta = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;

resolutionFactor = round(resolution / delta);
resolutionFactor = resolutionFactor * [resolutionFactor > 0] + [resolutionFactor == 0];  %No less than one.

xV = x1 : delta * resolutionFactor : x3;
yV = y1 : delta * resolutionFactor : y2;
zV = zValues(slice1:slice2);  %Could be nonuniform in z.

[x3M, y3M, z3M] = meshgrid(xV, yV, zV);
[cM, rM, sM] = meshgrid(1:length(xV), length(yV): -1 :1, 1:(slice2-slice1)+1); %Corresponding indices

CERRStatusString('Get doses...')
%Get doses at these points
doses3M = zeros(size(x3M));
[dosesV] = getDoseAt(stateS.doseSet, x3M(:), y3M(:), z3M(:), planC);

CERRStatusString('Get distances...')
%Now get the distance from each one of these points to the surface points.
dist3M = zeros(size(x3M));
doses3M = zeros(size(x3M));
CERRStatusString(['Number of surface points is: ' num2str(length(xSurfV))])
h = waitbar(0,'Constructing distance transform and dose map...');
iMax = length(x3M(:));

surfacePoints = [xSurfV ySurfV zSurfV]';

for i  = 1 : iMax
%   rTmpSq = (x3M(i) - xSurfV).^2 +  (y3M(i)-ySurfV).^2 +  (z3M(i)-zSurfV).^2;
  rTmpSq = sepsq(surfacePoints, [x3M(i);y3M(i);z3M(i)]);
  rSq = min(rTmpSq);
  dist3M(rM(i),cM(i),sM(i)) = rSq^0.5;
  doses3M(rM(i),cM(i),sM(i)) = dosesV(i);
  if rem(i,100) == 0
    waitbar(i/iMax,h)
  end
end
close(h)

clear x3M y3M z3M  rM cM sM dosesV

%Distinguish interior from exterior
[mask3MU, zValues] = getMask3D(structNum,planC);


%Get subsection:
region3MU = mask3MU(min(rV): resolutionFactor : max(rV), min(cV): resolutionFactor: max(cV), slice1:slice2);

dist3M = dist3M .* [region3MU == 0]  - dist3M .* [region3MU == 1]; %interior points are negative.

if nargin > 4
  CERRStatusString('Remove points outside skin...')
  %Get skin outline if asked for:
  [skin3MU, zValues] = getMask3D(skinNum,planC);
  %Get subsection:
  skin3MU = skin3MU(min(rV): resolutionFactor : max(rV), min(cV): resolutionFactor: max(cV), slice1:slice2);
  for i  = 1 : size(skin3MU,3)
    im = skin3MU(:,:,i);
    edges = im & [del2(double(im))~=0];
    edges = [edges ~= 0];
    noEdges = im & [~edges];
    skin3MU(:,:,i) = noEdges;
  end
  dist3M = dist3M .* [skin3MU == 1]  + 9999999999 .* [skin3MU == 0]; %interior points are negative.
end

CERRStatusString('Index and bin...')

%Create index map:
ind3M = round(dist3M/resolution);

%Get unique map of indexes:
indList = unique(ind3M(:));

%Loop through indices
dosesV = zeros(size(indList));
doseDistV = zeros(size(indList));
iMax = length(indList);
for i = 1 : length(indList)
  indV = find(ind3M == indList(i));
  tmpV = doses3M(indV);
  tmpV = tmpV(:)';

  if strcmpi(minOrMax,'min')
    val = min(tmpV);
  elseif strcmpi(minOrMax,'max')
    val = max(tmpV);
  elseif strcmpi(minOrMax,'mean')
    val = mean(tmpV);
  end
  doseDistV(i) = val;
end

xAxis = indList * resolution;

ind2V = find([xAxis > minDistance + 1000 * eps]);
if ~isempty(ind2V)
  ind2V = ind2V(1);
  xAxis = xAxis(1:ind2V-1);
  doseDistV = doseDistV(1:ind2V-1);
end

if ~exist('noPlot')
  noPlot = 'plot';
end

if ~strcmpi(noPlot,'noplot')
  sName = lower(planC{indexS.structures}(structNum).structureName);
  ddpFig = figure;
  ddp = plot(xAxis,doseDistV,'bo-');
  set(ddpFig,'tag','CERRDDPlots');
  xlabel('Contour distance (cm)')
  str = getDoseUnitsStr(stateS.doseSet,planC);
  ylabel(['Contour dose (' str ')'])
  title(['Dose-distance plot for ' sName '; plotting ' minOrMax ' contour doses.'])
  grid on


  set(ddpFig,'name',['Dose-distance plot for: ' stateS.CERRFile])
  stateS.handle.DDPlots = findobj('tag','CERRDDPlots');  %Find them all
end

CERRStatusString('')








