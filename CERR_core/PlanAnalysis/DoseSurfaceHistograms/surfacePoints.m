function [xV, yV, lengthV] = surfacePoints(verM, deltaLim)
%"surfacePoints"
%   This function returns the coordinates of points sampled along the
%   surface of the polygon defined by the verM matrix:
%   xV is x-values in the AAPM coordinate frame,
%   yV is y-values, lengthV is the length of the sample
%   interval along the edge.  This function is used to generate 
%   dose-surface-histograms (DSH's).
%
%   This code works by cycling through the polygon edges, and assigning 
%   each edge at least one point.  If the edge is longer than deltaLim 
%   then points are added along the edge.  The number of points along an 
%   edge is ceil(length/delta), linearly spaced.  Points are sampled as:
%       V--p----p----p----p--V, where V is a vertex and p is a sample point.
%   That is, each sample point is in the middle of an interval.  Intervals 
%   are of different sizes for different edges.
%
%LM:  19 Feb 02, JOD.
%     24 Feb 05, JRA. Reformatted header, comment.
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
%
%Usage:
%   [xV, yV, lengthV] = surfacePoints(verM, deltaLim)

%Close the contour if need be.
if any(verM(1,1:2)~=verM(end,1:2))
    verM = [verM; verM(1,:)]
end

xV      = [];
yV      = [];
lengthV = [];

%Cycle through edges:
for i = 1 : size(verM,1) - 1
    x1 = verM(i,1);  x2 = verM(i+1,1);  y1 = verM(i,2); y2 = verM(i + 1,2);
    %Compute length of edge:
    len = ((x1 - x2).^2 + (y1 - y2).^2).^0.5;
    if len ~= 0
        %Num intervals needed:
        ints = ceil(len/deltaLim);  %There will aways be at least one interval/sample point.
        delta = len/ints;  %This is the size of an interval around sample points.
        lambdaV = (1/2 * delta: delta : len - 1/2 * delta) / len;
        tmp_xV = (1-lambdaV) * x1 + lambdaV * x2;
        tmp_yV = (1-lambdaV) * y1 + lambdaV * y2;
        xV = [xV; tmp_xV(:)];
        yV = [yV; tmp_yV(:)];
        tmp_lengthV = ones(length(tmp_xV),1) * delta;
        lengthV = [lengthV; tmp_lengthV(:)];
    end
end















