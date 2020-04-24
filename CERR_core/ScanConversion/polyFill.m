function result = polyFill(xSize, ySize, rowV, colV)
%function result = polyFill(xSize, ySize, rowV, colV)
%
%Author: Tim Simpson
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

% Initialize our mask to zero.  The algorithm will then fill in all the
% places enclosed by the contours with a 1
result = zeros(xSize, ySize);

% Some contours have more than one segment.  We basically treat this like
% a seperate polygon on the same image.  They shouldn't overlap, but if
% they do, the value of the resultant mask will just be the composite of
% the two (all mask values will be 1.0).
pointCount = length(rowV);
edgeList = zeros(pointCount,4);

% NOTE : Even if a segment has zero points, the points
% structure still shows up with 1 empty point, so I skip the
% write out unless it's greater than 1
for point = 1 : pointCount
    if (point == pointCount)
        p1x = rowV(point);
        p1y = colV(point);
        p2x = rowV(1);
        p2y = colV(1);
    else
        p1x = rowV(point);
        p1y = colV(point);
        p2x = rowV(point + 1);
        p2y = colV(point + 1);
    end

    % Just in case the polygon isn't closed, this will close it
    % If the polygon is closed, this just adds a 0 length edge that
    % will be drawn as a single pixel on top of an already existing
    % edge endpoint (ie it will have no effect on the mask if the
    % polygon is already closed).
    if (p1y <= p2y)
        % edgeList = [edgeList; [p1x p1y p2x p2y]];
        edgeList(point,:) = [p1x p1y p2x p2y];
    else
        %edgeList = [edgeList; [p2x p2y p1x p1y]];
        edgeList(point,:) = [p2x p2y p1x p1y];
    end
end

% Let's get some min and max values to limit the space we're
% considering.  There's no need to consider a bunch of empty lines.
minY = min(edgeList(:,2));
maxY = max(edgeList(:,4));

% Loop over the relevant lines in the image.
for y = ceil(minY):floor(maxY)
    % Basically, don't pay any attention to edges that don't cover the
    % y value of the line we're considering.  There might be room for
    % improvement here if the number of edges becomes very large, but
    % for now this seems to be pretty quick.
    indV = edgeList(:,2) <= y & edgeList(:,4) >= y;
    activeEdges = edgeList(indV,:);  

    % Create two lists, one for pixels we know we need to draw called
    % drawlist (for flat lines and peaks / valleys) and one for places
    % where we've calculated an intersection and we know we need to
    % toggle our painting algorithm called togglelist (for your normal
    % sloped lines that pass through this y value).
    drawlist = [];
    togglelist = [];

    % Iterate over the active edges
    edgeCount = size(activeEdges,1);
    for edge = 1 : edgeCount
        % Consider the edge from (p1x,p1y) to (p2x, p2y)
        p1x = activeEdges(edge,1);
        p1y = activeEdges(edge,2);
        p2x = activeEdges(edge,3);
        p2y = activeEdges(edge,4);

        % Check to see if it's a flat line
        if (p1y == p2y)
            % If it's a flat line, figure out which way the edges are
            % oriented and record the x values in the list of pixels we
            % know need to be on.
            if (p1x > p2x)
                drawlist = [drawlist ceil(p2x):floor(p1x)];
            else
                drawlist = [drawlist ceil(p1x):floor(p2x)];
            end
        elseif (p2y == y && p2x == round(p2x))
            drawlist = [drawlist p2x];
        elseif p2y ~= y
            invslope = double(p2x - p1x) / double(p2y - p1y);
            togglelist = [togglelist (p1x + (invslope * (y - p1y)))];
        end
    end

    % In order to pair start stop points correctly, need to make sure
    % we consider our toggle points in order
    togglelist = sort(togglelist);

    % It's worth noting that we are guaranteed pairs of toggle points
    % if the polygon is closed, which it should be, since we added a
    % closing edge just in case it wasn't.

    % Iterate over pairs in our toggle list
    for i = 1:2:length(togglelist)
        % This only paints pixels if the center of the pixel is inside
        % the polygon. For each pair, the 'paint' will initially be
        % off. This means that for the first value of the pair, we will
        % push the intersection to the next available pixel center
        % (unless it is already on one).  Likewise, for any second
        % value of the pair, we will push the intersection value to the
        % previous pixel center (unless it is already on one).
        result(ceil(togglelist(i)):floor(togglelist(i+1)),y) = 1;
    end
    % Don't forget to simply turn on those pixels we recorded earlier.
    result(drawlist, y) = 1;
end

return
