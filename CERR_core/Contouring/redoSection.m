function [xV, yV, segNum] = redoSection(hCERR)
%function [xV, yV, segNum] = redoSection(hCERR)
%'Snip' & Redo a section of the active contour.
%Directions:  click (Button 1) once where the redone section should begin,
%             then click again where the section should end.  After the section
%             is deleted, fill in from the first point to the second, with
%             Button 1 creating points and button 2 closing the contour.
%
%Called by contourControls.
%LM:  2 April 02, JOD.
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

%Get the start point:

hPlot = getActiveSegment;
segS = get(hPlot,'userdata');
xV = segS.GUI_xV;
yV = segS.GUI_yV;
segNum = segS.segNum;

hold on
[x, y, button]  = ginput(1);

if isempty(button)
  xV = [];
  yV = [];
  return
end

switch button  %Maybe more options in the future?

  case 1

    rV = ((x - xV).^2 + (y - yV).^2 ).^0.5;
    indV = find(rV == min(rV));
    ind_a = indV(1);

end

%Now get the ending point:
[x, y, button]  = ginput(1);

if isempty(button)
  xV = [];
  yV = [];
  return
end

switch button

  case 1 %get nearest point

    rV = ((x - xV).^2 + (y - yV).^2 ).^0.5;
    indV = find(rV == min(rV));
    ind_b = indV(1);

end

%reorganize xV and yV:
%ind_b becomes the first point, and ind_a becomes the last point.
%Also: snip the shortest path in terms of number of points.
len = length(xV);
if ind_b > ind_a
  %which path is smallest?
  path1 = ind_b - ind_a;
  path2 = ind_a + (len - ind_b);
  if path1 <= path2
    xV = [xV(ind_b:end),xV(1:ind_a)];
    yV = [yV(ind_b:end),yV(1:ind_a)];
  else
    xV = [xV(ind_a:ind_b)];
    yV = [yV(ind_a:ind_b)];
    xV = fliplr(xV);
    yV = fliplr(yV);
  end
else  %ind_a > ind_b
  %which path is smallest?
  path1 = ind_a - ind_b;
  path2 = ind_b + (len - ind_a);
  if path1 <= path2
    xV = [xV(ind_a:end),xV(1:ind_b)];
    yV = [yV(ind_a:end),yV(1:ind_b)];
    xV = fliplr(xV);
    yV = fliplr(yV);
  else
    xV = [xV(ind_b:ind_a)];
    yV = [yV(ind_b:ind_a)];
  end
end

%Plot remaining segment
delete(hPlot)
hPlot2 = plot(xV,yV,'rs-');  %plot closed contour
set(hPlot2,'markersize',4)

%Go into new segment mode:
xLast = xV(end);
yLast = yV(end);

finished = 0;
hLineV = [];
while ~finished
  [x, y, button] = ginput(1);
  if button == 3
    finished = 1;
  else
    xV = [xV, x];
    yV = [yV, y];
    h = plot([xLast, x],[yLast, y],'rs-');
    set(h,'markersize',4)
    hLineV = [hLineV, h];
    xLast = x;
    yLast = y;
  end

end

delete(hLineV)
delete(hPlot2)

x2V = [xV, xV(1)];
y2V = [yV, yV(1)];

hPlot = plot(x2V,y2V,'rs-');
set(hPlot,'markersize',4)

hold off

%segmentsS contains all the information about the plotted segments - it gets written into
%the userdata portion of any segment.

segS.active = 1;
segS.hPlot  = hPlot;
segS.GUI_xV = xV;
segS.GUI_yV = yV;

set(hPlot,'tag','newSegment')
set(hPlot,'userdata',segS)

