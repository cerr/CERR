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


[xRange, yRange] = getAxisInfo(hAxis, 'xRange', 'yRange');

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

set(hAxis, 'xLim', [midpoint_x - newDeltaX/2 midpoint_x + newDeltaX/2]);
set(hAxis, 'yLim', [midpoint_y - newDeltaY/2 midpoint_y + newDeltaY/2]);