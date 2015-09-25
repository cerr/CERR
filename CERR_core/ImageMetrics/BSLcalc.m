function [BSL,BKG] = BSLcalc(Wsheds,removeShed)
%
%
%
%% BSL calc

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

minShed = min(nonzeros(ShedTmp(:)));
maxShed = max(nonzeros(ShedTmp(:)));

SUVcut = 0.2;
ShedTmp(ShedTmp < SUVcut) = 0;
 
% Shed Trimming
k = 0;
voxVec = [];
while ( sum(ShedTmp(:)) > 0 )
    k = k + 1;
    minShed = min(nonzeros(ShedTmp(:)));
    indS = find(ShedTmp == minShed);
    ShedTmp(indS) = 0;    
    if (k > removeShed)
        voxVec = [voxVec PT(indS)'];
    end
end

if (sum(voxVec) <=0)
    BSL = -1;
    return
end

nVox = numel(voxVec);
SUViqr = iqr(voxVec);
IVHBinWidth = 2 * SUViqr * nVox^(-1/3);

[binHistV, volHistV]  = doseHist(voxVec, voxVol*ones(size(voxVec)), IVHBinWidth);
nBins = numel(binHistV);

[Hmax iBkg] = max(volHistV);
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
SUVcut = Hbkg/3;
voxVec(voxVec < SUVcut) = 0;
voxVec = nonzeros(voxVec);

nVox = numel(voxVec);
SUViqr = iqr(voxVec);
IVHBinWidth = 2 * SUViqr * nVox^(-1/3);

[binHistV, volHistV]  = doseHist(voxVec, voxVol*ones(size(voxVec)), IVHBinWidth);
nBins = numel(binHistV);
plot(binHistV,volHistV), drawnow

%% Gaussian FITS
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

sL2 = [];
initVar = [ Hmax*sqrt(2*pi())*Hbkg Hbkg SUViqr ];
lBound =  [ 0.01  0.01  0.01  ];
uBound =  [ inf   inf   inf  ];

sL2  = lsqnonlin(@(X) (...
    ( volHistV(minusBins:plusBins) - X(1)*normpdf(binHistV(minusBins:plusBins),X(2),X(3)) ) ...
    / sum(volHistV(minusBins:plusBins)) ).*sqrt(volHistV(minusBins:plusBins)), ...
    initVar,lBound,uBound,fitOptions);

estGauss2 = sL2(1)*normpdf(binHistV(:),sL2(2),sL2(3));

BKG = sL2(2);

%% Volume and TLG Estimation
iEst2 = round( 2*sL2(3)/IVHBinWidth + sL2(2)/IVHBinWidth );
if  (sL2(2) <= 0)
    iEst2 = round( 2*sL2(3)/IVHBinWidth + iBkg );
end
volGauss2 = estGauss2(iEst2:end);

% Gauss volumes
vecG2 = zeros(size(volGauss2));
vecG2 = volHistV(iEst2:end)' - volGauss2;
vecG2(vecG2 < 0) = 0;
volG2 = sum(vecG2);

BSL = vecG2'*binHistV(iEst2:end)';
