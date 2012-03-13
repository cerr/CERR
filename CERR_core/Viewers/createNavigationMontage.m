function planC = createNavigationMontage(planC)
%function createNavigationMontage(varargin)
%Sets up a montage of the CT scans on CERR
%import.
%
%JOD, 29 May 03.
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


thumbWidth = 64;  %width of thumbnail views


indexS = planC{end};

numSlices = length(planC{indexS.scan}.scanInfo);

w = planC{indexS.scan}.scanInfo(1).sizeOfDimension1;

sample = w/thumbWidth;

filterWidth = 1 + 1.5 * sample;

h = (1/filterWidth)*ones(filterWidth);  %Set simple filter

scan3M = getScanArray(planC{indexS.scan});

smooth3M = zeros(thumbWidth,thumbWidth,numSlices);


bar = waitbar(0,'Generate thumbnails of CT images...');
for i = 1 : numSlices

    %get ct data:
    ct = scan3M(:,:,i);
    tmp = filter2(h,ct);
    smooth3M(:,:,i) = getDownsample2(tmp,sample);
    waitbar(i/numSlices,bar)

end

im = CERRMontage(smooth3M);

close(bar)

planC{indexS.scan}.thumbnails.montage = im;

width = stateS.navInfo.thumbWidth;

n = stateS.navInfo.numImages;

across = stateS.navInfo.numImagesAcross;
down = stateS.navInfo.numImagesDown;


%-----------end main---------------------%
function [im, down, across] = CERRMontage(smooth3M)

%Fix the size of the array:

n = size(smooth3M,3);

across = ceil(n^0.5);

if across * (across -1) >= n
 down = across -1 ;
else
 down = across;
end

width = size(smooth3M,1);

%fill in:

im = zeros(width*down,width*across);

count = 0;

for i = 1 : down

    for j = 1 : across

        count = count + 1;
        if count <= n
          im((i-1) * width + 1 : (i-1) * width + width, (j-1) * width + 1 : (j-1) * width + width) = smooth3M(:,:,count);
        end

    end

end


