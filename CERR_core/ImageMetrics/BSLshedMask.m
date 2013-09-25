function  mShed = BSLshedMask(Wsheds,Cut)
%"BSLshedMask"
%   BSL subfunction -- Returns WS masks used for a BSL estimate made with a
%   user specified number of low activity regions removed
%
% CRS 05/20/13
%
%Usage:
%   mShed = BSLshedMask(Wsheds,Cut)
%       Wsheds = watershed masks for the region
%       Cut    = Specifies the number of sheds removed
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
%% BSL watershed mask calc

PT = Wsheds.PET;
Shed = Wsheds.Shed;
voxVol = Wsheds.voxVol;
[pX pY pZ] = size(PT);

% build shed masks
ShedTmp = zeros(size(PT));
indNZ = find(Shed);
Shed(isnan(Shed)) = 0;
Shed(isinf(Shed)) = 0;
ShedTmp(indNZ) = Shed(indNZ);

% removes very low background (i.e. bkg outside of patient)
SUVcut = 0.2;
ShedTmp(ShedTmp < SUVcut) = 0;
PT(ShedTmp <= 0) = 0;

% Shed trimming sucessively removing the lowest remaining shed
for k = 0:Cut
    minShed = min(nonzeros(ShedTmp(:)));
    indS = find(ShedTmp == minShed);
    ShedTmp(indS) = 0;
    PT(indS) = 0;
    if (isempty(indS) == 1)
        k = k - 1;
        continue
    end
end

if (sum(ShedTmp(:)) <=0)
    mPT = -1;
    return
end

mShed = ShedTmp;
mShed(mShed > 0) = 1;
voxVec = nonzeros(mShed.*PT);

% preliminary histogram estimate given the shed cuts
nVox = numel(voxVec);
SUViqr = iqr(voxVec);
IVHBinWidth = 2 * SUViqr * nVox^(-1/3);

[binHistV, volHistV]  = doseHist(voxVec, voxVol*ones(size(voxVec)), IVHBinWidth);
nBins = numel(binHistV);

% preliminary BKG estimate using histogram peak
[Hmax, iBkg] = max(volHistV);
Hbkg = binHistV(iBkg);
if (iBkg > 1 && iBkg < numel(binHistV))
    Hbkg = ( volHistV(iBkg-1)*binHistV(iBkg-1) ...
        + volHistV(iBkg)*binHistV(iBkg) ...
        + volHistV(iBkg+1)*binHistV(iBkg+1) ) ...
        / ( volHistV(iBkg-1) + volHistV(iBkg) + volHistV(iBkg+1) );
else
    if (iBkg < numel(binHistV))
        Hbkg = ( volHistV(iBkg)*binHistV(iBkg) ...
            + volHistV(iBkg+1)*binHistV(iBkg+1) ) ...
            / ( volHistV(iBkg) + volHistV(iBkg+1) );
    else
        Hbkg = ( volHistV(iBkg-1)*binHistV(iBkg-1) ...
            + volHistV(iBkg)*binHistV(iBkg) ) ...
            / ( volHistV(iBkg-1) + volHistV(iBkg) );
    end
end
% removes some activity from the left side of the histogram to remove
% fitting bias from activity below the background
SUVcut = Hbkg/3;
mShed(PT < SUVcut) = 0;
