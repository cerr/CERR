function [maxBSL,BKG,Thresh,equiVol,mPT,bsl] = BSLestimate(PT,maskRTS,voxVol)
%"BSLestimate"
%   Wrapper for Background Subtracted Lesion Estimation -- Returns BSL
%   estimate, Background estimate, Effective Thershold esimate, 
%   Equivalent Volume estmate, and WS mask used for estimate.  
%
% CRS 05/20/13
%
%Usage: 
%   [maxBSL,BKG,Thresh,equiVol,mPT] = BSLestimate(PT,maskRTS,voxVol)
%       PT      = PET images in SUV
%       maskRTS = VOI mask for restricting the BSL estimate
%       voxVol  = volume of a voxel in ml
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
%% preprocess slices for WS
regPad = [2 2];
s0 = regionprops(maskRTS, {'Centroid','BoundingBox'});
x0(1) = s0.BoundingBox(2); x0(2) = s0.BoundingBox(2+3);
y0(1) = s0.BoundingBox(1); y0(2) = s0.BoundingBox(1+3);
z0(1) = s0.BoundingBox(3); z0(2) = s0.BoundingBox(3+3);
X = floor(x0(1) + 1 - regPad(1):x0(1) + x0(2) + regPad(1));
Y = floor(y0(1) + 1 - regPad(2):y0(1) + y0(2) + regPad(2));
Z = floor(z0(1) + 1:z0(1) + z0(2));
regionPT = PT(X,Y,Z);
maskPT = maskRTS(X,Y,Z);

%% Compute Water Sheds
[Sheds,nShedsT] = BSLwatershed(regionPT,maskPT);
Sheds = maskPT.*Sheds;

Wsheds = struct( ...
    'Shed',Sheds, ...
    'PET',maskPT.*regionPT, ...
    'voxVol',voxVol ...
    );

%% Calculate BSL
[bsl,bkg] = BSLcalcShedsVis(Wsheds,nShedsT,0);

%% Find Max BSL & Background
sBSL = smooth(bsl, max(ceil(numel(bsl)/15),8));
% figure,plot(bsl,'-k'), hold on
% plot(sBSL,'-r'), hold off
[maxBSL, imaxBSL] = max(sBSL);
BKG = bkg(imaxBSL);

% Get WS Region Mask
mPT = zeros(size(PT));
mPTregion = BSLshedMaskVis(Wsheds,imaxBSL);
mPT(X,Y,Z) = mPTregion;

% Get equivalent volume and threshold
[Thresh, equiVol] = BSLthresh(Wsheds,maxBSL);

return

