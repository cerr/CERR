function [Tshed,nShedsT] = BSLwatershed(regionPT,maskPT)
%"BSLwatershed"
%   BSL subfunction -- Returns watersheds for BSL estimate and the total
%   number of non-zero watersheds
%
% CRS 05/20/13
%
%Usage: 
%   [Tshed,nShedsT] = BSLwatershed(regionPT,maskPT)
%       regionPT = subregion from PET images in SUV
%       maskPT   = VOI mask for restricting the watersheds
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
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.%
%
%% Smooth region to limit WS over-segmentation 
smoothPT = fspecial('gaussian', 9, 3);
bPT = imfilter(regionPT,smoothPT,'replicate','same','conv');
bPT(bPT < 0) = 0;

%% Build 2D Watershed Transform of Region
Tshed = zeros(size(regionPT));
for i = 1:size(regionPT,3)
    
    % get slices
    PTtemp  = regionPT(:,:,i);
    bPTtemp = bPT(:,:,i);
    
    % get sheds
    % performs a 2D WS on an upsampled gradient image to remove boundary
    % elements
    hy = fspecial('sobel'); hx = hy';
    DelY = imfilter(double(PTtemp), hy, 'replicate');
    DelX = imfilter(double(PTtemp), hx, 'replicate');
    gradmagS = imresize(sqrt(DelX.^2 + DelY.^2),32*size(bPTtemp),'bicubic');
    Ls = double(watershed(gradmagS,8));
    % Down Samples the WS image to reduce the number of boundary elements
    L = imresize(Ls,size(bPTtemp),'nearest');
    
    %% Detemines the number of sheds for memory allocation
    Shed = []; ShedVal = []; meanShed = [];
    k = 0;
    for j = 1:max(L(:));
        if ( numel(find(maskPT(:,:,i).*L == j)) ~= 0 )
            k = k + 1;
        end
    end
    nSheds(i) = k;
    Shed = zeros([ size(PTtemp) nSheds(i)]);
    
    % reorders sheds from low to highest mean SUV and builds masks
    k = 0;
    for j = 1:max(L(:));
        if ( numel(find(maskPT(:,:,i).*L == j)) ~= 0 )
            k = k + 1;
            mShed = double(L);
            mShed(mShed ~= j) = 0;
            mShed(mShed > 0) = 1;
            Shed(:,:,k) = mShed.*PTtemp;
            ShedVal(k) = mean(nonzeros(Shed(:,:,k)));
            meanShed(:,:,k) = mShed*ShedVal(k);
        end
    end
    [~,Ival] = sort(ShedVal);
    Shed = Shed(:,:,Ival);
    meanShed = meanShed(:,:,Ival);
    
    % bulds a total shed from the means of each WS
    TmpShed = zeros(size(L));
    for j = 1:nSheds(i), TmpShed = meanShed(:,:,j) + TmpShed; end
    TmpShed1 = TmpShed;
    
    %% Unclassified voxel assignment 
    % Finds unclassified voxels
    Cracks = double(L);
    Cracks(Cracks ~= 0) = 0.5; Cracks(Cracks == 0) = 1; Cracks(Cracks < 1)  = 0;
    iCrack = find(Cracks); Cracks = Cracks.*PTtemp;
    % Fill in unclassified voxels using the nearest mean shed value from
    % NEWS (k < 3) avoids infinite loop 
    k = 0;
    while (sum(Cracks(:)) > 0  && k < 3)
        k = k + 1;
        [mSize, nSize] = size(L);
        for j = 1:numel(iCrack)
            q = floor( ( iCrack(j)-1 ) / mSize ) + 1;
            p = mod(iCrack(j),mSize);
            if (p == 0), p = mSize; end
            jT = p-1 + (q-1)*mSize; jB = p+1 + (q-1)*mSize;
            jL = p   + (q-2)*mSize; jR = p   + (q)*mSize;
            
            iVal = []; jCross = [];
            if (p > 1 && p < mSize)
                if (q > 1 && q < nSize), jCross = [ jT jB jL jR ];
                else
                    if (q > 1), jCross = [ jT jB jL ];
                    else jCross = [ jT jB jR ];
                    end
                end
            else
                if (p > 1)
                    if (q > 1 && q < nSize), jCross = [ jT jL jR ];
                    else
                        if (q > 1), jCross = [ jT jL ];
                        else jCross = [ jT jR ];
                        end
                    end
                else
                    if (q > 1), jCross = [ jB jL ];
                    else jCross = [ jB jR ];
                    end
                end
            end
            [~, iVal] = min(abs( TmpShed(jCross) - Cracks(iCrack(j)) ));
            if (TmpShed(jCross(iVal)) == 0)
                TmpShed1(iCrack(j)) = Cracks(iCrack(j));
            else
                TmpShed1(iCrack(j)) = TmpShed(jCross(iVal));
            end
        end
        TmpShed = TmpShed1;
        Cracks = TmpShed;
        Cracks(Cracks ~= 0) = 0.5; Cracks(Cracks == 0) = 1; Cracks(Cracks < 1)  = 0;
        iCrack = find(Cracks); Cracks = Cracks.*PTtemp;
    end
    Tshed(:,:,i) = TmpShed1;
    
end
nShedsT = sum(nSheds);

