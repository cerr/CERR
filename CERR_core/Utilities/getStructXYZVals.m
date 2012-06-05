function [xVals, yVals, zVals, usedRasters] = getStructXYZVals(structures)
%"getStructXYZVals"
%   Returns the x, y, and z values needed to create a grid to display 
%   the passed structures. If rasterSegments exist for the structures, they
%   are interpolated to provide a likely gridsize and coordinate system if
%   enough suitable segments are available.  Otherwise, a default value of 
%   256x256x(number of slices in structures) is used for the array, and the
%   sturcture's contours are used to create suitable x,y,z values.
%
%   usedRasters is a boolean indicating whether raster segments were used.
%
%   By JRA 12/26/03
%
%   structures        : planC{indexS.structures}
%
%   xVals,yVals,zVals : x,y,z Values for structs
%
% Usage:
%   function [xVals, yVals, zVals, usedRasters] = getStructXYZVals(structures)
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


resolutions = [256 512]; %default resolutions
usedRasters = 1;

%First, try using old rasterSegments to determine x,y,z vals.
segs = vertcat(structures.rasterSegments);
if ~isempty(segs)
    zVals = unique(segs(:,1))';
    
    [partYVals, yInd] = unique(segs(:,2));    
    [partXVals, xInd] = unique(segs(:,3));
    
    %Enough unique values to form a grid.
    if length(partYVals) > 2 & length(partXVals > 2)
   
        rows = segs(yInd,7);
        cols = segs(xInd,8);
        
        %Set res to nearest resolution value above it.
        upperLim = max(max(rows), max(cols));
        resInd = min(find(upperLim < resolutions));
        %If upperLim is over the biggest res, use it as the res.
        res = max([resolutions(resInd) upperLim]);
        
        %Interpolate the values for the limits
        xLims   = interp1(cols, partXVals, [1 res], 'linear', 'extrap');
        colLims = interp1(partXVals, cols, xLims, 'linear', 'extrap');
        
        yLims   = interp1(rows, partYVals, [1 res], 'linear', 'extrap');
        rowLims = interp1(partYVals, rows, yLims, 'linear', 'extrap');
        
        numRows = round(diff(rowLims) + 1);
        numCols = round(diff(colLims) + 1);
        
        xVals = xLims(1):diff(xLims)/(numCols-1):xLims(2);
        yVals = yLims(1):diff(yLims)/(numRows-1):yLims(2);
        return;
    end   
end

%If raster segments dont exist, use the contour's values and default to a
%256x256 grid.
usedRasters = 0;

numRows = 256;
numCols = 256;

xMin = inf;
xMax = -inf;
yMin = inf;
yMax = -inf;

zVals = [];

%Get max and min for X and Y.
for i=1:length(structures)
%    segs = [structures(i).contour.segments];
    for j=1:length(structures(i).contour)
       segs = [structures(i).contour(j).segments];
       if isfield(segs,'points')
           pts = vertcat(segs.points);
       else
           pts = vertcat(segs);
       end
       maxV = max(pts);
       minV = min(pts);
       if isempty(maxV)
           continue;
       end
       xMin = min(xMin, minV(1));
       xMax = max(xMax, maxV(1));
       
       yMin = min(yMin, minV(2));
       yMax = max(yMax, maxV(2));
       
       if isfield(segs,'points')
           zVals(j) = pts(1,3);
       else
           zVals = [zVals pts(1,3)];
       end
    end
end

if ~isfield(segs,'points')
    zVals = unique(sort(zVals));
end

xWid = (xMax-xMin);
yWid = (yMax-yMin);
%Square pixels off by using larger of x/y
if xWid > yWid
    margin = (xWid - yWid)/2;
    xVals = xMin:xWid/(numCols-1):xMax;
    yVals = yMin-margin:xWid/(numRows-1):yMax+margin;    
else
    margin = (yWid - xWid)/2;
    yVals = yMin:yWid/(numCols-1):yMax;
    xVals = xMin-margin:yWid/(numRows-1):xMax+margin;  
end
yVals = fliplr(yVals);

defSlices = find(zVals);
needSlices = setdiff(1:length(structures(1).contour), defSlices);
zVals(needSlices) = interp1(defSlices, zVals(defSlices), needSlices, 'linear', 'extrap');


%zVals = sort(unique(zVals));