function [planC,statT] = getSemiQuantMetricsForDCEMR(planC,strNum,...
    createMapsFlag,varargin)
% [planC,statT] = getSemiQuantMetricsForDCEMR(planC,strNum,...
%    createMapsFlag,varargin);
%==========================================================================
% INPUTS
% planC : CERR archive
% strNum: Structure number
% createMapsFlag : Save parameter maps if flag is set to 1 (off:0).
% --- Optional -----
% varargin{1} :  Flag for temporal smoothing (Default:0)
% varargin{2} :  Flag for resampling         (Default:0)
% varargin{3} :  Spatial smoothing filter size & sigma
%                filtV =[fSize, fSigma] (Default: no smoothing)
%==========================================================================
% AI 11/12/2020

%% Check inputs
minargs = 3;
maxargs = 6;
narginchk(minargs,maxargs);
% Set defaults
smoothFlag = 0;
resampFlag = 0;
filtV = 0;
optArgC = {smoothFlag,resampFlag,filtV};
% Replace with user input where available
numOptIns = nargin-minargs;
[optArgC{1:numOptIns}] = varargin{:};
[smoothFlag,resampFlag,filtV] = optArgC{:};
indexS = planC{end};
% Construct spatial smoothing filt (if reqd)
if ~filtV==0
    fSize = filtV(1);
    fSigma = filtV(2);
    hFilt = fspecial('gaussian',11,5); %fSize=11, fSigma=5
end

%% Get masked data
%Extract mask
assocScanNum = getStructureAssociatedScan(strNum, planC);
sizV = size(getScanArray(assocScanNum,planC));
mask3M = false(sizV);

rasterSegments = getRasterSegments(strNum,planC);
[mask,roiSlicesV] = rasterToMask(rasterSegments,assocScanNum,planC);
mask3M(:,:,roiSlicesV) = mask;
nMaskSlices = numel(roiSlicesV);

%Apply mask
scanS = planC{indexS.scan};
sizV = [sizV(1),sizV(2),numel(scanS),sizV(3)];
filtSlice3M = zeros(sizV(1:3));
normDCE4M = zeros(sizV(1),sizV(2),sizV(3),nMaskSlices);
for n = 1:nMaskSlices
    
    %Get data
    sliceC = arrayfun(@(x) x.scanArray(:,:,roiSlicesV(n)),scanS,'un',0);
    slice3M = double(cat(3,sliceC{:}));
    
    %Smooth
    if ~filtV==0
        for l = 1:size(filtSlice3M,3)
            filtSlice3M(:,:,l) = filter2(hFilt,slice3M(:,:,l));
        end
    else
        filtSlice3M = slice3M;
    end
    
    %Mask data
    maskM = mask3M(:,:,roiSlicesV(n));
    maskedDCE3M = bsxfun(@times,filtSlice3M,maskM);
    if n==1
        %Get user-input shift to start of uptake curve
        [shift,nbase] = getShift(maskedDCE3M,maskM);
    end
    %Normalize
    base3M = maskedDCE3M(:,:,1:nbase); %Baseline signal
    baseM = mean(base3M,3);            %Mean baseline signal
    baseM(baseM==0) = eps;
    normDCE4M(:,:,:,roiSlicesV(n)) = bsxfun(@rdivide,maskedDCE3M,baseM);
end


%% Get time pts (in min) of DCE image acquisition
timeV = getAcqTime(scanS);
%Apply shift correction
timeShiftV = timeV - timeV(shift+1);
timeShiftV = timeShiftV(shift+1:end);
normDCEShift4M = normDCE4M(:,:,shift+1:end,:);

%% Get T50, s50
CERRStatusString('Computing TTHP...','console');
for n = 1:nMaskSlices
    [ROIidxV,ROIDataM] = getRasterROI(normDCEShift4M(:,:,:,roiSlicesV(n)));
    
    %Compute semi-quantitative parameters
    [resampSigM,TTHPv,SHPv,timeOutV] = halfPeak(ROIDataM,timeShiftV,smoothFlag,resampFlag);
    paramS = calcSemiQuantParams(resampSigM,timeOutV,TTHPv,SHPv);
    
    %Concatentate metrics across slices
    paramsC = fieldnames(paramS);
    paramCatC = cell(length(paramsC),1);
    for nPar = 1:length(paramsC)
        if n==1
            temp = [];
        else
            temp = paramCatC{nPar};
        end
        paramV = paramS.(paramsC{nPar});
        paramCatC{nPar} = [temp,paramV];
    end
    
    %Create maps
    if createMapsFlag
        mapsC = cell(length(paramsC),1);
        for nPar = 1:length(paramsC)
            if ~isempty(paramS.(paramsC{nPar}))
                mapV = zeros(sizV(1)*sizV(2),1);
                mapV(ROIidxV) = paramS.(paramsC{nPar});
                if n==1
                    map3M = zeros(sizV(1),sizV(2),sizV(4));
                else
                    map3M = mapsC{nPar};
                end
                map3M(:,:,roiSlicesV(n)) = reshape(mapV,sizV(2),sizV(1)).';
                mapsC{nPar} = map3M;
            end
        end
    end
end

%% Compute statistics
statC = {'NumVoxels','NumOutliers','FractionRetained','Mean','Median',...
    'StdDev','Variance','pct_10','pct_90','Skewness','Kurtosis'};
statM = nan(numel(paramsC),numel(statC));
statT = array2table(statM,'variablenames',statC,'rownames', paramsC);
for nPar = 1:length(paramsC)
    if isempty(paramCatC{nPar})
        statT(nPar,:) = num2cell(nan(1,length(statC)));
    else
        paramV = paramCatC{nPar};
        statsV = calcStats(paramV);
        statT(nPar,:) = num2cell(statsV);
    end
end

%% Add maps to planC
if createMapsFlag
    scanNum = getStructureAssociatedScan(strNum,planC);
    [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
    dx = abs(mean(diff(xVals)));
    dy = abs(mean(diff(yVals)));
    dz = abs(mean(diff(zVals)));
    deltaXYZv = [dy dx dz];
    regParamsS.horizontalGridInterval = deltaXYZv(1);
    regParamsS.verticalGridInterval   = deltaXYZv(2);
    regParamsS.coord1OFFirstPoint   = xVals(1);
    regParamsS.coord2OFFirstPoint   = yVals(sizV(1));
    regParamsS.zValues  = zVals;
    regParamsS.sliceThickness =[planC{indexS.scan}(scanNum).scanInfo(:).sliceThickness];
    
    for nPar = 1:length(paramsC)
        if ~isempty(mapsC{nPar})
            assocTextureUID = createUID('texture');
            planC = scan2CERR(mapsC{nPar},paramsC{nPar},'Passed',regParamsS,...
                assocTextureUID,planC);
        end
    end
    
    CERRStatusString('Complete.','console');
end


%% -- Sub-functions --
    function [shift,nbase] = getShift(maskedDCE3M,maskM)
        [i,j] = find(maskM);
        ROISigM = (maskedDCE3M(i,j,:));
        avgROIsigV = squeeze(sum(sum(ROISigM)))/size(maskedDCE3M,3);
        h = figure('Name','ROI avg signal');
        plot(0:length(avgROIsigV)-1,avgROIsigV,'-dr');
        inShift = inputdlg('Enter shift (time) to start of uptake curve)','User-input shift');
        shift = str2num(inShift{1});
        if isempty(shift) || shift<1
            error('Invalid input: user shift');
            return
        end
        close(h)
        % Get number of baseline points (prior to uptake)
        if shift>1
            nbase = shift-1;
        else
            nbase = 1;
        end
    end

    function yV = calcStats(xV)
        paramIQR = iqr(xV);
        q1 = prctile(xV,25);
        q3 = prctile(xV,75);
        outliersV = xV < q1-2.5*paramIQR | xV > q3+2.5*paramIQR;
        xxV = xV(~outliersV);
        yV = [numel(xV),numel(xV)-numel(xxV),numel(xxV)/numel(xV),nanmean(xxV),...
            nanmedian(xxV),nanstd(xxV),nanvar(xxV),prctile(xxV,10),prctile(xxV,90),...
            skewness(xxV),kurtosis(xxV)];
    end

end