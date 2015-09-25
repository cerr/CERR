function [BSL,BKG] = BSLcalcSheds(Wsheds,nSheds)
%"BSLshedMask"
%   BSL subfunction -- Returns a BSL and BKG estimate using the supplied
%   watershed masks
%
% CRS 05/20/13
%
%Usage: 
%   [BSL,BKG] = BSLcalcSheds(Wsheds,nSheds)
%       Wsheds = watershed masks for the region
%       nSheds = Specifies the number of shed masks 
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
%% BSL calc for all sheds
bsl = zeros([nSheds 1]);
bkg = zeros([nSheds 1]);

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
k = 0;
while ( sum(ShedTmp(:)) > 0 )
    voxVec = [];
    minShed = min(nonzeros(ShedTmp(:)));
    indS = find(ShedTmp == minShed);
    ShedTmp(indS) = 0;
    PT(indS) = 0;
    if (isempty(indS) == 1)
        continue
    end
    k = k + 1;
    voxVec = nonzeros(PT);
    
    if (sum(voxVec) <=0)
        bsl(k) = -1;
        bkg(k) = -1;
        BKG = bkg(1:k);
        BSL = bsl(1:k);
        return
    end
    
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
    voxVec(voxVec < SUVcut) = 0;
    voxVec = nonzeros(voxVec);
    ShedTmp(ShedTmp < SUVcut) = 0;
    PT(ShedTmp < SUVcut) = 0;
    
    % final histogram with all relevant activity removed
    nVox = numel(voxVec);
    SUViqr = iqr(voxVec);
    IVHBinWidth = 2 * SUViqr * nVox^(-1/3);
    
    [binHistV, volHistV]  = doseHist(voxVec, voxVol*ones(size(voxVec)), IVHBinWidth);
    nBins = numel(binHistV);

    %% Gaussian fitting region
    fitOptions = optimset('Display','off');
    lBins = ceil(SUViqr/IVHBinWidth);
    
    plusBins  = iBkg + lBins;
    if (plusBins > numel(binHistV))
        plusBins = numel(binHistV);
    end
    minusBins = iBkg  - lBins;
    if (minusBins < 1)
        minusBins = 1;
    end
    if (numel(minusBins:plusBins) < 3)
        if (minusBins+2 <= numel(binHistV))
            plusBins = minusBins + 2;
        else
            minusBins = plusBins - 2;
        end
    end
    
    % inital estiamtes
    lsqEst = [];
    initVar = [ Hmax*sqrt(2*pi())*Hbkg Hbkg SUViqr ];
    lBound =  [ 0.01  0.01  0.01  ];
    uBound =  [ inf   inf   inf  ];
    
    % weighted least squares fit normalized to total volume
    lsqEst  = lsqnonlin(@(X) (sqrt(volHistV(minusBins:plusBins)) .* ...
         ( ( volHistV(minusBins:plusBins) ...
         - X(1)*normpdf(binHistV(minusBins:plusBins),X(2),X(3)) ) ...
        / sum(volHistV(minusBins:plusBins)) ) ), ...
        initVar,lBound,uBound,fitOptions);
    
    estGauss = lsqEst(1)*normpdf(binHistV(:),lsqEst(2),lsqEst(3));
    % BKG estimate
    bkg(k) = lsqEst(2);
    if (isnan(bkg(k)) || isinf(bkg(k)) ), bkg(k) = -1; end
    
    %% Volume and TLG Estimation
    iEst = round( 2*lsqEst(3)/IVHBinWidth + lsqEst(2)/IVHBinWidth );
    if  (lsqEst(2) <= 0)
        iEst = round( 2*lsqEst(3)/IVHBinWidth + iBkg );
    end
    volGauss = estGauss(iEst:end);
    
    % Gauss volumes
    vecG = zeros(size(volGauss));
    vecG = volHistV(iEst:end)' - volGauss;
    vecG(vecG < 0) = 0;
    volG2 = sum(vecG);
    
    bsl(k) = vecG'*binHistV(iEst:end)';
    if (isnan(bsl(k)) || isinf(bsl(k)) ), bsl(k) = -1; end
    
    if (bsl(k) <= 0 && k > nSheds/5)
        BKG = bkg(1:k);
        BSL = bsl(1:k);
        return;
    end
    
end
BKG = bkg(1:k);
BSL = bsl(1:k);

