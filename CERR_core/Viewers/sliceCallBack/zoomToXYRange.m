function zoomToXYRange(hAxis)
%"zoomTOXYRange"
%   Sets the zoom level on the passed CERR axis to the values in its
%   xRange, yRange parameters.
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

[xRange, yRange, viewAx] = getAxisInfo(hAxis, 'xRange', 'yRange', 'view');

%Cannot zoom axes that have no x, y range values.  Set them to auto and
%return.
if isempty(xRange) || isempty(yRange)
    axis(hAxis, 'auto', 'equal');
    return;
else
    axis(hAxis, 'manual');
end

%Get current axis values.
position = get(hAxis, 'position');
xyRatio = position(3)/position(4);

%Get requested axis values.
delta_x_req = diff(xRange);
delta_y_req = diff(yRange);
midpoint_x = mean(xRange);
midpoint_y = mean(yRange);

requestedRatio = delta_x_req/delta_y_req;

if requestedRatio > xyRatio
    %x is limiting.
    newDeltaX = delta_x_req;
    newDeltaY = newDeltaX/xyRatio;
else
    %y is limiting.
    newDeltaY = delta_y_req;
    newDeltaX = newDeltaY * xyRatio;
end

xLim        = [midpoint_x - newDeltaX/2 midpoint_x + newDeltaX/2];
%deltaX      = num2str(xLim(2) - xLim(1), '%0.4g');
yLim        = [midpoint_y - newDeltaY/2 midpoint_y + newDeltaY/2];

set(hAxis, 'xLim', xLim);
set(hAxis, 'yLim', yLim);

%Show 5cm bar to display zoom-level
len = 5; %cm
switch upper(viewAx)
    case 'TRANSVERSE'
        dx = xLim(2)-xLim(1);
        xStart = xLim(1) + dx * 0.05;
        xEnd = xStart + len;
        dy = yLim(2)-yLim(1);
        yStart = yLim(1) + dy * 0.05;
        yEnd = yStart + len;
    case 'SAGITTAL'
        dx = xLim(2)-xLim(1);
        xStart = xLim(2) - dx * 0.05;
        xEnd = xStart - len;
        dy = yLim(2)-yLim(1);
        yStart = yLim(2) - dy * 0.05;
        yEnd = yStart - len;        
    case 'CORONAL'
            dx = xLim(2)-xLim(1);
            xStart = xLim(1) + dx * 0.05;
            xEnd = xStart + len;
            dy = yLim(2)-yLim(1);
            yStart = yLim(2) - dy * 0.05;
            yEnd = yStart - len;
    case 'LEGEND'
        return;
end
xAll = linspace(xStart,xEnd,6);
yAll = linspace(yStart,yEnd,6);

i = find(stateS.handle.CERRAxis == hAxis);
for j = 1:size(stateS.handle.CERRAxisTicks1,2)
    set(stateS.handle.CERRAxisTicks1(i,j),'xData',[xAll(j) xAll(j)], 'yData', [yStart-dy*0.0025 yStart+dy*0.0025],'visible','on')
    set(stateS.handle.CERRAxisTicks2(i,j),'xData',[xStart-dx*0.0025 xStart+dx*0.0025], 'yData', [yAll(j) yAll(j)],'visible','on')
end

set(stateS.handle.CERRAxisScale1(i),'xData',[xStart xEnd], 'yData', [yStart yStart],'visible','on')
set(stateS.handle.CERRAxisScale2(i),'xData',[xStart xStart], 'yData', [yStart yEnd],'visible','on')
