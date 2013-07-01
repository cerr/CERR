function [BSL,BKG] = BSLcalcSheds(Wsheds,nSheds,IMAGE)
%
%
%
%% BSL calc for all sheds
if (IMAGE == 1)
    figure,
end
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

SUVcut = 0.2;
ShedTmp(ShedTmp < SUVcut) = 0;
PT(ShedTmp <= 0) = 0;

% Shed Trimming
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
        if (IMAGE ~= 0)
            hold off
        end
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
    ShedTmp(ShedTmp < SUVcut) = 0;
    PT(ShedTmp < SUVcut) = 0;
    
    nVox = numel(voxVec);
    SUViqr = iqr(voxVec);
    IVHBinWidth = 2 * SUViqr * nVox^(-1/3);
    
    [binHistV, volHistV]  = doseHist(voxVec, voxVol*ones(size(voxVec)), IVHBinWidth);
    nBins = numel(binHistV);
    if (IMAGE == 1)
        colorWidth = 2;
        colorPlot = mod(k,7);
        switch colorPlot
            case (1)
                plot(binHistV,volHistV,'-c','LineWidth',colorWidth)
            case (2)
                plot(binHistV,volHistV,'-g','LineWidth',colorWidth)
            case (3)
                plot(binHistV,volHistV,'-y','LineWidth',colorWidth)
            case (4)
                plot(binHistV,volHistV,'-r','LineWidth',colorWidth)
            case (5)
                plot(binHistV,volHistV,'-k','LineWidth',colorWidth)
            case (6)
                plot(binHistV,volHistV,'-m','LineWidth',colorWidth)
            otherwise
                plot(binHistV,volHistV,'-b','LineWidth',colorWidth)
        end
        drawnow, hold on
    end
    if (IMAGE == 2)
        plot3(binHistV,-k*ones(numel(binHistV)),volHistV), drawnow
        hold on
    end
    if (IMAGE == 3)
        colorWidth = 4;
        colorPlot = mod(k,7);
        switch colorPlot
            case (1)
                plot(binHistV,volHistV,'-c','LineWidth',colorWidth)
            case (2)
                plot(binHistV,volHistV,'-g','LineWidth',colorWidth)
            case (3)
                plot(binHistV,volHistV,'-y','LineWidth',colorWidth)
            case (4)
                plot(binHistV,volHistV,'-r','LineWidth',colorWidth)
            case (5)
                plot(binHistV,volHistV,'-k','LineWidth',colorWidth)
            case (6)
                plot(binHistV,volHistV,'-m','LineWidth',colorWidth)
            otherwise
                plot(binHistV,volHistV,'-b','LineWidth',colorWidth)
        end
        drawnow, hold on
    end
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
    if (numel(minusBins:plusBins) < 3)
        if (minusBins+2 <= numel(binHistV))
            plusBins = minusBins + 2;
        else
            minusBins = plusBins - 2;
        end
    end
    if (minusBins < 1)
        BKG = bkg(1:k);
        BSL = bsl(1:k);
        if (IMAGE ~= 0)
            hold off
        end
        return
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
    
    bkg(k) = sL2(2);
    
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
    
    bsl(k) = vecG2'*binHistV(iEst2:end)';
    if (bsl(k) <= 0 && k > nSheds/10)
        BKG = bkg(1:k);
        BSL = bsl(1:k);
        if (IMAGE ~= 0)
            hold off
        end
        return;
    end
    
end
BKG = bkg(1:k);
BSL = bsl(1:k);
if (IMAGE ~= 0)
    hold off
end

