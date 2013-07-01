function [Thresh, equiVol] = BSLthresh(Wsheds,maxBSL)
%"BSLthresh"
%   BSL subfunction -- Returns the threshold and equivalent volume for a
%   given BSL value
%
% CRS 05/20/13
%
%Usage:
%   [Thresh, equiVol] = BSLthresh(Wsheds,maxBSL)
%       Wsheds = watershed masks for the region
%       maxBSL = Specifies the BSL where the equivalent thershold is
%       estimated
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
%% BSL calc
PT = Wsheds.PET;
voxVol = Wsheds.voxVol;
[pX pY pZ] = size(PT);

voxVec = nonzeros(PT);
voxVec(isnan(voxVec)) = 0;
voxVec(isinf(voxVec)) = 0;
voxVec = nonzeros(voxVec);

% histogram of data
nVox = numel(voxVec);
SUViqr = iqr(voxVec);
IVHBinWidth = 2 * SUViqr * nVox^(-1/3);

[binHistV, volHistV]  = doseHist(voxVec, voxVol*ones(size(voxVec)), IVHBinWidth);
nBins = numel(binHistV);

BSLEst = 0; k = numel(volHistV)+1;
while (BSLEst <= maxBSL && k > 1)
    k = k - 1;
    BSLEst = volHistV(k:end)*binHistV(k:end)';
    equiVol = sum(volHistV(k:end));
end

Thresh = binHistV(k)/max(PT(:));
