function [maskM] = scanPoly(edgeM, optS)
%function [maskM] = scanPoly(edgeM,optS)
%This function takes a list of polygon vertices, polyM,
%and returns a maskM matrix which is a 0-1 mask of
%points interior to the polygon.  The first column of polyM is
%the x vertices (in AAPM coordinates), the second column of polyM
%is the y vertices.  It is assumed that x= 0, y = 0 is the center of the image,
%which must have an even number of rows and columns.
%
%segmentsM holds the mask in 'scan segment' format:
%each row of this 2-D matrix has the elements:
%yvalue, xstart, xstop, deltax (all in AAPM coordinates).
%xstart and xstop are the points at which the filled-in segment
%begins and ends; yvalue is the y-value of that row.  deltax is the
%interval between x values.
%
%Needed option settings are:
%  imageSizeV      = optS.ROIImageSize, = [rows, columns] of resulting mask.
%  xPixelWidth     = optS.ROIxVoxelWidth (in cm),
%  yPixelWidth     = optS.ROIyVoxelWidth (in cm).
%
%The algorithm works by labelling edges as left or right bounding and top or bottom bounding.
%For each edge a point, consisting of one point per scan line, appropriate
%for the edge type (LT, LB, RT, or RB).  Store column indices of points in cell
%associated with that scan line.
%
%The algorithm nearly always includes only pixels whose midpoints are inside the polygon.
%This is typically not done in standard polygon scan algorithms.
%
%J.O.Deasy, deasy@radonc.wustl.edu
%LM: 11 Apr 02, JOD.
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


%Create the mask image:
imageSizeV = double(optS.ROIImageSize);

numEdges = size(edgeM,1);

%Find the two (or more) edges associated with the ymin vertex:
ymin = min(edgeM(:,2));
indV = find( edgeM(:,2) == ymin);

%Get the one with the lowest x value, with ymin being the first point listed
ind1 = indV(find( edgeM(indV,1) == min(edgeM(indV,1)) ));
ind1 = ind1(1); %for the rare case that two edges fulfill this criteria.


%Is this first 'prime' edge top or bottom?  Which edge is to the left?
%Get the x pts at the upper y value which is least for the
%two edges - the order the x values; then decide which
%is the left edge; then decide which is the top edge.

%In case the first edge is vertical:
lastTB = -1;

%Get the index of the neighboring edge:
if ind1 ~= 1
    ind2 = ind1 - 1;
else
    ind2 = numEdges;
end

%Now classify starting edge top or bottom, left or right.

%Special case: ymin edge is horizontal
if edgeM(ind1,2) == edgeM(ind1,4)
    lastTB = -1;
    %Is the vertex partner to the left or right?
    if edgeM(ind2,1) < edgeM(ind1,1)
      lastLR = -1;
    else
      lastLR = 1;
    end

    sdx = sign(edgeM(ind1,4) - edgeM(ind1,2));
    sdy = 1;  %This value doesn't matter.

else
    %Get the minimum of the max y of the vertex partners
    ymax_min = min([edgeM(ind1,4), edgeM(ind2,2)]);
    %Get the x value at ymax_min for the prime edge
    lambda = (ymax_min - ymin) / (edgeM(ind1,4) - ymin);
    x1 = (edgeM(ind1,3) - edgeM(ind1,1)) * lambda + edgeM(ind1,1);
    if edgeM(ind2,2) ~= edgeM(ind2,4) %non-horizontal
      lambda = (ymax_min - ymin) / (edgeM(ind2,2) - ymin);
      x2 = (edgeM(ind2,1) - edgeM(ind2,3)) * lambda + edgeM(ind2,3);
    else
      x2 = edgeM(ind2,1);
    end

    if x1 < x2
      lastLR = 1;
    else
      lastLR = -1;
    end

    sdx = sign(edgeM(ind1,3) - edgeM(ind1,1));

    %Now classify:
    if lastLR == 1 & sdx == -1
      lastTB = -1;
    elseif lastLR == 1 & sdx == 1
      lastTB = 1;
    elseif lastLR == -1 & sdx == -1
      lastTB = 1;
    elseif lastLR == -1 & sdx == 1
      lastTB = -1;
    else %Vetical edge:
      lastTB = lastTB;
    end
end

last_sdx = sdx;
if edgeM(ind1,4) ~= edgeM(ind1,2)
  last_sdy = sign(edgeM(ind1,4) - edgeM(ind1,2));
else
  last_sdy = 1;  %dummy - doesn't matter
end

LRV = zeros(1,numEdges);
TBV = zeros(1,numEdges);

LRV(ind1) = lastLR;
TBV(ind1) = lastTB;

%Loop through edges and assign edges Left or Right and Top or Bottom.
indicesV = [ind1:numEdges, 1:ind1-1];
indicesV(1) = []; %we've already done the first point.

for ind = indicesV

  dy = edgeM(ind,4) - edgeM(ind,2);
  dx = edgeM(ind,3) - edgeM(ind,1);

  sdy = sign(dy);
  sdx = sign(dx);

  %This is how we handle vertical or horizontal lines:
  if sdy == 0, sdy = last_sdy; end
  if sdx == 0, sdx = last_sdx; end

  parity_y = sdy * last_sdy;
  parity_x = sdx * last_sdx;

  LR = lastLR * parity_y;
  TB = lastTB * parity_x;

  LRV(ind) = LR;
  TBV(ind) = TB;

  lastLR = LR;
  lastTB = TB;

  last_sdy = sdy;
  last_sdx = sdx;

end


%Loop through edges in order, so that bounding and connecting
%rules can be applied.

%Rules for neighboring edges:  in the transition L -> R or R -> L, both edges must
%have points on the same extreme scan line.
%In all other cases, neighboring edges must not share the same scan line.

%For each edge:
%1.  Get x indices.
%2.  Decide where to put points.  For L edges, choose integer x point to the
%right of the x intersection; for R edges choose x integer to the left of the
%intersection.
%3.  Decide whether endpoint point is needed for L->R type transition.
%(Note:  endpoints never overlap with point from last edge unless
%L->R or R->L transition.  This is due to the rule that the bottom edge
%is perturbed upward by epsilon to avoid having two edges have a y intersection
%exactly at a voxel midpoint.)

%If we try to put an endpoint in scanM where an endpoint already exists,
%we follow the rules that (a)  If we have a start and a stop,
%we put a point into maskM and eliminate any points in scanM,
%and (b) if it is the same type we do not modify the entry.

%Two matrices:
%For 'sliver points', i.e. where the scan line starts and stops at the same point,
%we just poke a point into maskM.
%Horizontal lines are also skipped, as they are better handled based on the connecting edges.
%For all start (1) or stop (-1) points, we poke a 1 or -1 into the matrix scanM.
%The final image adds maskM to processed scanM.

%For top bounding line, always take the x point

startM = zeros(imageSizeV);
stopM  = zeros(imageSizeV);
maskM = zeros(imageSizeV);

for i = 1 : numEdges

  y1 = edgeM(i,2);
  y2 = edgeM(i,4);

  a = min(y1,y2);
  b = max(y1,y2);

  %Get integer points between:
  int1 = ceil(a);
  if rem(b,1) ~=0   %To keep from double marking ends at integer y values
    int2 = floor(b);
  else
    int2 = b - 1;
  end

  yIntV = int1 : int2;

  if ~isempty(yIntV) & y1 ~= y2  %i.e. the line crosses at least one scan mid-line
   %and y's are not equal integers.  Ignore horizontal lines.

    %Get x values at each y point, along with integer x values.
    len = length(yIntV);
    xV = zeros(1,len);
    n = (edgeM(i,3) - edgeM(i,1))/(edgeM(i,4) - edgeM(i,2));  % n = 1/slope,
    xV = edgeM(i,1) + n * (yIntV - edgeM(i,2));

    %Decide which integer points to take:
    %This preferentially takes points to the inside of a countour!
    if LRV(i) == 1
      xIntV = ceil(xV);
    else
       xIntV = floor(xV);
    end

    %convert y values to rows:
    rowV = imageSizeV(1) - yIntV + 1;

    %Put 1's into scanM
    indexV = rowV + imageSizeV(1) * (xIntV - 1);

    if LRV(i) == 1
      startM(indexV) = startM(indexV) + 1;
    else
      stopM(indexV) = stopM(indexV) + 1;
    end


  end

end

%Final processing

%I.  Fix pathological spikes.
%II. The result is the scan line form.

%Fix pathological spikes

%shift startM to the left:
shiftStartM = [startM(:,2:end), startM(:,1)];

testM = shiftStartM.*stopM;

[iV, jV] = find([testM == -1]);

if ~isempty(iV)  %check to see if this is pathological or just a neighboring scan segments.

  for i = 1 : length(iV)
    %Add up start values to column jV(i)
    numStarts = cumsum(startM(iV(i),1:jV(i)));
    numStops  = cumsum(stopM(iV(i),1:jV(i)));
    if numStarts ~= numStops  %It is pathological
      %mutual annihilation
      startM(iV(i),jV(i)+1) = startM(iV(i),jV(i)+1) - 1;
      stopM(iV(i),jV(i)+1)  = stopM(iV(i),jV(i)+1) - 1;
    end
  end

end

%Get single point spikes:
[iV, jV] = find([startM.*stopM > 0]);

if ~isempty(iV)
  indV = iV+size(maskM,1)*(jV-1);
  mask(indV) = 1;
  startM(indV) = startM(indV) - 1;
  stopM(indV)  = stopM(indV) - 1;
end

%As a test, now convert to scan:
scanM = startM - stopM;

dim = 2;
scanM = cumsum(scanM,dim) + [scanM == -1];

%Get final mask
maskM = [[scanM + maskM] ~= 0];

%fini!


if ~any(maskM) & ~isempty(edgeM)
    dist = sqrt((edgeM(:,1) - edgeM(:,3)).^2 + (edgeM(:,2) - edgeM(:,4)).^2);
    if dist == 0
        maskM = zeros(optS.ROIImageSize);
        return;
    end
    normDist = dist / sum(dist);
    pts = edgeM .* repmat(normDist, [1 4]);
    tmp = sum(pts);
    coord = mean([tmp(1:2);tmp(3:4)]);
    final = round(coord);
    siz = size(maskM);
    maskM(siz(1) - final(2), final(1)) = 1;
end

