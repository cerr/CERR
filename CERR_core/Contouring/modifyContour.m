function [xV, yV] = modifyContour(hCERR)
%function [xV, yV] = modifyContour(hCERR)
%Modify the active contour
%Button 1 Moves the nearest point to the mouse point.
%Button 2 Adds a point along the neares segment at the mouse point.
%Called by contourControls.
%JOD.
%LM:  2 Dec 02, JOD.
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


figure(hCERR)

hold on
[x, y, button]  = ginput(1);

if isempty(button)
  xV = [];
  yV = [];
  return
end

hPlot = getActiveSegment;
segS = get(hPlot,'userdata');
xV = segS.GUI_xV;
yV = segS.GUI_yV;

switch button

  case 1 %replace nearest point

    rV = ((x - xV).^2 + (y - yV).^2 ).^0.5;
    indV = find(rV == min(rV));
    ind = indV(1);
    xV(ind) = x;
    yV(ind) = y;
    delete(hPlot)
    hPlot = plot([xV,xV(1)],[yV,yV(1)],'rs-');  %plot closed contour
    set(hPlot,'markersize',4)

  case 3 %add point along nearest edge

    %Cycle through all the line segments just to be sure we get the nearest perpindicular
    rV = ((x - xV).^2 + (y - yV).^2 ).^0.5;
    indV = find(rV == min(rV));
    ind0 = indV(1);
    r0V = [x, y];
    cycleLength = length(xV);
    nearest = -1;
    bestDist = 999999;
    ind_a = [];
    for i = 1 : cycleLength;
      indTest1 = ind0 + i - 1;
      [ind1] = cycle(indTest1, cycleLength);
      indTest2 = ind0 + i;
      [ind2] = cycle(indTest2, cycleLength);
      r1V = [xV(ind1),yV(ind1)];
      r2V = [xV(ind2),yV(ind2)];
      %Does the perpendicular hit on the line segment?
      [dist, flag1] = dist2seg(r0V, r1V, r2V);
      if flag1 == 0 & dist < bestDist
        ind_a = ind1;
        ind_b = ind2;
        bestDist = dist;
        nearest = i;
      end
    end

    %Compare with distances to nearest neighbors
    indTest = ind0 -1;
    cycleLength = length(xV);
    [ind1] = cycle(indTest, cycleLength);
    indTest = ind0 + 1;
    [ind2] = cycle(indTest, cycleLength);
    r1 = ((x - xV(ind1)).^2 + (y - yV(ind1)).^2 )^0.5;
    r2 = ((x - xV(ind2)).^2 + (y - yV(ind2)).^2 )^0.5;
    if  (r1 < r2 & r1 < bestDist)
        ind_a = ind0;
        ind_b = ind1;
    elseif r2 < bestDist
        ind_a = ind0;
        ind_b = ind2;
    end

    %Plug the new point in:
    if abs(ind_a - ind_b) == 1 %no end-wrapping
      insert1 = min(ind_a,ind_b);
      xV = [xV(1:insert1), x, xV(insert1+1:end)];
      yV = [yV(1:insert1), y, yV(insert1+1:end)];
    else  %case of end-wrapping
      xV = [xV, x];
      yV = [yV, y];
    end

    %redraw
    delete(hPlot)
    hPlot = plot([xV,xV(1)],[yV,yV(1)],'rs-');  %Only plot with same first and last point; store no duplicates
    set(hPlot,'markersize',4)

end

hold off


%segmentsS contains all the information about the plotted segments - it gets written into
%the userdata portion of any segment.

segS.active = 1;
stateS.activeSegment = segS.segNum;
segS.hPlot  = hPlot;
segS.GUI_xV = xV;
segS.GUI_yV = yV;

set(hPlot,'tag','newSegment')
set(hPlot,'userdata',segS)

