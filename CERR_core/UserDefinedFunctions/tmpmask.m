function tmpmask(varargin)
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

global planC stateS

indexS =  planC{end}

structNum = str2num(varargin{1});

ROIImageSize   = [planC{indexS.scan}.scanInfo(1).sizeOfDimension1  planC{indexS.scan}.scanInfo(1).sizeOfDimension2];
zValue         = planC{indexS.scan}.scanInfo(stateS.sliceNum).zValue;

[segmentsM, planC, isError] = getRasterSegments(structNum, planC);    
%segmentsM = planC{indexS.structures}(structNum).rasterSegments;

indV = find(abs(segmentsM(:,1) - zValue) < 10 * eps);  %mask values on this slice

segmentsM = segmentsM(indV(:),7:9);     %segments


%reconstruct the mask:
maskM = zeros(ROIImageSize);
for i = 1 : size(segmentsM,1)
  maskM(segmentsM(i,1),segmentsM(i,2):segmentsM(i,3)) = 1;
end

%f = figure; contour(maskM,[0.5])

%set(f,'tag','t')

%return
%Next make a mask which is this but expanded by 3 cm or 15 pixels.

f = findobj('tag','t')

figure(f)
[X,Y] = meshgrid(-5:.2:5, -5:.2:5);

roll = (X.^2 + Y.^2).^0.5 <= 3.0001;

%now convolve roll with maskM:

mask2M = conv2(maskM,roll,'same');
hold on
contour(mask2M,0.5)
hold off



