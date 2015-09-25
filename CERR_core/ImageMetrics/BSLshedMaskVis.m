function  mPT = BSLshedMaskVis(Wsheds,Cut)
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
mPT = PT;
mPT(mPT > 0) = 1;

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

voxVec = nonzeros(mShed.*PT);

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
bkg = lsqEst(2);
if (isnan(bkg) || isinf(bkg) ), bkg = -1; end

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
volG = sum(vecG);

bsl = vecG'*binHistV(iEst:end)';
if (isnan(bsl) || isinf(bsl) ), bsl = -1; end

% Differential Histogram
SUVmax = max(PT(:));
bin42 = 0.42*SUVmax;

volEst = 0; k = numel(volHistV)+1;
while (volEst < volG)
    k = k - 1;
    volEst = sum(volHistV(k:end));
    binG = binHistV(k);   
end
% figure,h = plot(binHistV, volHistV,'-k','LineWidth',2);
% title('Lesion Differential Histogram','fontsize',48,'fontweight','b')
% xlabel('SUV','fontsize',40,'fontweight','b')
% ylabel('Volume (ml)','fontsize',40,'fontweight','b')
% xmin = 0; xmax = ceil(SUVmax);
% ymin = 0; ymax = 1.05*ceil(volHistV(iBkg));
% axis([xmin xmax ymin ymax])
% hold on
% plot(binHistV,estGauss,'-r','LineWidth',2)
% %plot(scanBinsV(minusBins:plusBins), volHistV(minusBins:plusBins)/volVoi,'--y','LineWidth',1.5)
% plot(binG*ones([numel(binHistV) 1]),0:ymax/(numel(binHistV)-1):ymax,'--r','LineWidth',4)
% plot(bin42*ones([numel(binHistV) 1]),0:ymax/(numel(binHistV)-1):ymax,'--g','LineWidth',4)
% if (SUVmax > 2.5)
%     plot(2.5*ones([numel(binHistV) 1]),0:ymax/(numel(binHistV)-1):ymax,'--b','LineWidth',4)
% end
% if (SUVmax <= 2.5)
%     legend('Lesion','Background Fit','BSL Cutoff','42% Threshold','Location','NorthEast');
% else
%     legend('Lesion','Background Fit','BSL Cutoff','42% Threshold','SUV 2.5','Location','NorthEast');
% end
% set(gca,'FontSize',34,'fontweight','b');
% hold off

% h = plot(binHistV, volHistV,'-k','LineWidth',2);
% xlabel('SUV','fontsize',8,'fontweight','b')
% ylabel('Volume (ml)','fontsize',8,'fontweight','b')
% xmin = 0; xmax = ceil(SUVmax);
% ymin = 0; ymax = 1.05*ceil(volHistV(iBkg));
% axis([xmin xmax ymin ymax])
% hold on
% plot(binHistV,estGauss,'-r','LineWidth',2)
% %plot(scanBinsV(minusBins:plusBins), volHistV(minusBins:plusBins)/volVoi,'--y','LineWidth',1.5)
% plot(binG*ones([numel(binHistV) 1]),0:ymax/(numel(binHistV)-1):ymax,'--r','LineWidth',3)
% plot(bin42*ones([numel(binHistV) 1]),0:ymax/(numel(binHistV)-1):ymax,'--g','LineWidth',3)
% if (SUVmax > 2.5)
%     plot(2.5*ones([numel(binHistV) 1]),0:ymax/(numel(binHistV)-1):ymax,'--b','LineWidth',3)
% end
% set(gca,'FontSize',8,'fontweight','b');
% hold off
% 



end