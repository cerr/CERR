function [mask3MU, xV, yV, zV] = getStructSurface(structNum,planC)
%Assemble the 3-D CT-registered mask of structure surface points (type UINT8),
%along with the x, y, and z coordinates of the surface points.
%JOD.
%Latest modifications:  JOD, 19 Feb 03, added zValues output.
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

indexS = planC{end};

ROIImageSize   = [planC{indexS.scan}.scanInfo(1).sizeOfDimension1  planC{indexS.scan}.scanInfo(1).sizeOfDimension2];

numSlices = length(planC{indexS.scan}.scanInfo);

mask3MU = uint8(zeros(ROIImageSize(1),ROIImageSize(2),numSlices));

zV = []; xV = []; yV = [];

zerosM = zeros(ROIImageSize(1),ROIImageSize(2));

for sliceNum = 1 : numSlices

  z    = planC{indexS.scan}.scanInfo(sliceNum).zValue;

  [segmentsM, planC, isError] = getRasterSegments(structNum, planC);
%  segmentsM = planC{indexS.structures}(structNum).rasterSegments;

  indV = find(segmentsM(:,1) == z);  %mask values on this slice

  segmentsM = segmentsM(indV(:),7:9);     %segments

  %reconstruct the mask:

  z1V = [];
  x1V = [];
  y1V = [];

  maskM = zerosM;
  for j = 1 : size(segmentsM,1)
    maskM(segmentsM(j,1),segmentsM(j,2):segmentsM(j,3)) = 1;
    tmpV = segmentsM(i,:);
    x0V = tmpV(3): tmpV(5) : tmpV(4);
    x1V = [x1V, x0V];
    len = length(xV);
    rangeV = ones(1,len);
    y0V = tmpV(2) * rangeV;
    z0V = tmpV(1) * rangeV;
    y1V = [y1V, y0V];
    z1V = [z1V, z0V];
  end

  surfM = [del2(maskM) .* maskM ~= 0];

  tmpM = surfM';
  tmpV = tmpM(:);

  [iV, jV, valV] = find(tmpV);

  %Keep only where valV is nonzero:
  ind2V = find(valV);

  x1V = x1V(ind2V); %Only keep surface points.
  y1V = y1V(ind2V);
  z1V = z1V(ind2V);

  mask3MU(:,:,sliceNum) = surfM;

  xV = [xV, x1V];
  yV = [yV, y1V];
  zV = [zV, z1V];

end

