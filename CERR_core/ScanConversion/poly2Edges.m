function [edgeM] = poly2Edges(polyM,optS)
%function [edgeM] = poly2Edges(polyM,optS)
%Convert from polygon vertices in AAPM coords to edges in pixel coordinates.
%
%LM:  12 Apr 02, JOD.
%LM:  27 Oct 05, DK. 
%     compatible with MATLAB version 7 
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


imageSizeV = optS.ROIImageSize;

%First convert to pixel-based coords:
xOffset = optS.xCTOffset;
yOffset = optS.yCTOffset;

MATLABVer = version;
if MATLABVer(1) ~= '6'
    imageSizeV = double(imageSizeV);
    xOffset    = double(xOffset);
    yOffset    = double(yOffset);
end
[rowV, colV]=aapmtom(polyM(:,1),polyM(:,2),xOffset,yOffset,imageSizeV, ...
              [optS.ROIyVoxelWidth, optS.ROIxVoxelWidth]);

if any(rowV < 1) | any(rowV > optS.ROIImageSize(1))
    if any(rowV+5 < 1) | any(rowV-5  > optS.ROIImageSize(1))
        warning('A row index is off the edge of image mask: these set of points will be discarded');
        edgeM = [];
        return
    end
    warning('A row index is off the edge of the image mask:  automatically shifting to the edge.')
    rowV = rowV .* ([rowV >= 1] & [rowV <= optS.ROIImageSize(1)]) + ...
           [rowV > optS.ROIImageSize(1)] .* optS.ROIImageSize(1) + ...
           [rowV < 1];
end

if any(colV < 1) | any(colV > optS.ROIImageSize(2))
    if any(colV+5 < 1) | any(colV-5  > optS.ROIImageSize(2))
        warning('A column index is off the edge of image mask: these set of points will be discarded');
        edgeM = [];
        return
    end
    warning('A column index is off the edge of the image mask:  automatically shifting to the edge.')
    colV = colV .* ([colV >= 1] & [colV <= optS.ROIImageSize(2)]) + ...
           [colV > optS.ROIImageSize(2)] .* optS.ROIImageSize(2) + ...
           [colV < 1];
end

yV = imageSizeV(1) - rowV + 1; %y = 1 is the last row; y increases with decreasing row number.
xV = colV;

pixelM = [xV, yV];

if any(pixelM(1,1:2)~=pixelM(end,1:2))
  error('This algorithm assumes that the first and last vertices are identical.')
end

%0.  Create the total edge list: each line is [xstart, ystart, xend, yend]
tmpM = pixelM(:,1:2);
tmpM(1,:) = [];
edgeM = [pixelM(1:end-1,1:2), tmpM];

