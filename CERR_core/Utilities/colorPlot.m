function colorPlot(xV, yV, zV, cV, cmap, style, minVal, maxVal)
%"colorPlot"
%   Plots 2d or 3d point data with each point taking a different color, as
%   defined by the passed colormap.
%
%   xV, yV, and optional zV are the vectors of the x,y,(z) coordinates of
%   points to plot.  If z is not required, set zV to [].
%
%   cV is a value that will be used to index into the colormap, ie a single
%   data value for each x,y,(z).
%
%   cmap, the colormap, is a Nx3 matrix of RGB colors.
%
%   style is a string denoting the vertex style, ie, 'o' or '.' etc.
%
%   minVal/maxVal are the cV values for the first and last colors in cmap,
%   and points will be linearly interpolated along the cmap scale with
%   points lower than minVal or higher than maxVal taking the end colors.
%   minVal and maxVal are optional: if they don't exist the min/max of cV
%   are used.
%
%JRA 04/06/05
%
%Usage:
%   2D: colorPlot(xV, yV, [], cV, cmap, style, minVal, maxVal)
%   3D: colorPlot(xV, yV, zV, cV, cmap, style, minVal, maxVal)
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

nX = length(xV);
nY = length(yV);
nZ = length(zV);

if isempty(zV)
    nDims = 2;
    if nX ~= nY
        error('xV and yV must be vectors of the same length.')    
    end
else
    nDims = 3;
    if nX ~= nY | nX ~= nZ
        error('xV and yV must be vectors of the same length.')    
    end    
end

if size(cmap, 2) ~= 3
    error('cmap must be a Nx3 matrix of RGB color values.');
end

if ~exist('minVal')
    minVal = min(cV(:));
end

if ~exist('maxVal')
    maxVal = max(cV(:));
end

if ~exist('style')
    style = 'o';
end

nColors = size(cmap, 1);

cV = clip(cV, minVal, maxVal, 'limits');
cV = (cV - minVal) / (maxVal - minVal);
cV = cV * (nColors-1);
cV = floor(cV+1);

hAxis = gca;
set(hAxis, 'nextplot', 'add');
for i=1:nX
    if nDims == 2
        plot(xV(i), yV(i), style, 'color', cmap(cV(i),:));
    else
        plot3(xV(i), yV(i), zV(i), style, 'color', cmap(cV(i),:));    
    end
end