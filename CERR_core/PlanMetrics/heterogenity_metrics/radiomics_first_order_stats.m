function RadiomicsFirstOrderS = radiomics_first_order_stats(planC,structNum,offsetForEnergy,binWidth)
%
% function RadiomicsFirstOrderS = radiomics_first_order_stats(planC,structNum,offsetForEnergy,binWidth)
%
%   First Order statistics
%
%--------------------------------------------------------------------------
%   08/11/2010, Ralph Leijenaar
%   - added Mean deviation
%  10/13/2017 APA Modified to handle matrix input (planC)
%  Eg: RadiomicsFirstOrderS = radiomics_first_order_stats(dataM);
%  07/13/2018 AI Bug fix for entropy calculation
%--------------------------------------------------------------------------

Step = 1;

if iscell(planC)
    indexS = planC{end};
    
    % Get uniformized structure Mask
    maskStruct3M = getUniformStr(structNum,planC);
    
    % Get uniformized scan mask in HU
    scanNum = getAssociatedScan(planC{indexS.structures}(structNum).assocScanUID, planC);
    maskScan3M = getUniformizedCTScan(1, scanNum, planC);
    % Convert to HU if image is of type CT
    if ~isempty(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset)
        maskScan3M = double(maskScan3M) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    end
    % Offset for energy calculation
    if ~exist('offsetForEnergy','var')
        if ~isempty(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset)
            offsetForEnergy = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
        else
            offsetForEnergy = 0;
        end
    end
    % Get Pixel-size
    [xUnifV, yUnifV, zUnifV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
    PixelSpacingXi = abs(xUnifV(2)-xUnifV(1));
    PixelSpacingYi = abs(yUnifV(2)-yUnifV(1));
    PixelSpacingZi = abs(zUnifV(2)-zUnifV(1));
    VoxelVol = PixelSpacingXi*PixelSpacingYi*PixelSpacingZi;
    
    % Iarray = Data.Image(~isnan(Data.Image));     %    Array of Image values
    indStructV = maskStruct3M(:) == 1;
    Iarray = maskScan3M(indStructV);
    
else
    if ~exist('offsetForEnergy','var')
        offsetForEnergy = 0;
    end
    
    Iarray = planC;
    VoxelVol = structNum;
end


% Calculate standard PET parameters
RadiomicsFirstOrderS.min           = nanmin(Iarray);
RadiomicsFirstOrderS.max           = nanmax(Iarray);
RadiomicsFirstOrderS.mean          = nanmean(Iarray);
RadiomicsFirstOrderS.range         = range(Iarray);
%RadiomicsFirstOrderS.std           = std(Iarray,1,'omitnan');
RadiomicsFirstOrderS.std           = nanstd(Iarray,1);
%RadiomicsFirstOrderS.var           = var(Iarray,1,'omitnan');
RadiomicsFirstOrderS.var           = nanvar(Iarray,1); 
RadiomicsFirstOrderS.median        = nanmedian(Iarray);

% Skewness is a measure of the asymmetry of the data around the sample mean.
% If skewness is negative, the data are spread out more to the left of the mean
% than to the right. If skewness is positive, the data are spread out more to the
% right. The skewness of the normal distribution (or any perfectly symmetric
% distribution) is zero.
RadiomicsFirstOrderS.skewness      = skewness(Iarray);

% Kurtosis is a measure of how outlier-prone a distribution is. The kurtosis
% of the normal distribution is 3. Distributions that are more outlier-prone
% than the normal distribution have kurtosis greater than 3; distributions
% that are less outlier-prone have kurtosis less than 3.
RadiomicsFirstOrderS.kurtosis      = kurtosis(Iarray) - 3;

% Entropy is a statistical measure of randomness that can be used to characterize
% the texture of the input image
% N = ceil( RadiomicsFirstOrderS.range/Step);  %
%RadiomicsFirstOrder.entropy       = entropy_radiomics(Iarray,N);

% J = entropyfilt(varargin); % Misschien voor long, waar zit de hoogste
% heterogeniteit?

% Entropy
if ~exist('binWidth','var')
    binWidth = 25;
end
% xmin = min(Iarray) + offsetForEnergy;
% edgeMin = xmin - rem(xmin,binwidth);
% edgeMin = 0; % to match pyradiomics definition
xmaxV = max(Iarray); % + offsetForEnergy;
xminV = min(Iarray);
offsetForEntropyV = zeros(1,size(xminV,2));
offsetForEntropyV(xminV<0) = -xminV(xminV<0);
%offsetForEntropyV = cast(offsetForEntropyV,'like',Iarray);
offsetForEntropyV = cast(offsetForEntropyV,class(Iarray)); %for octave


xmaxV = xmaxV + offsetForEntropyV;
xminV = xminV + offsetForEntropyV;
edgeMaxV = xmaxV;
edgeMinV = xminV;
idxV =  abs(rem(edgeMaxV,binWidth)) > 0;
edgeMaxV(idxV) = edgeMaxV(idxV) + binWidth - rem(edgeMaxV(idxV),binWidth);
idxV = abs(rem(xminV,binWidth)) > 0;
edgeMinV(idxV) = edgeMinV(idxV) - rem(edgeMinV(idxV),binWidth);  
%---fix---
edgeMaxV(edgeMaxV==edgeMinV) = binWidth;
%--------

entropyV = nan(1,size(Iarray,2));
%entropyV = cast(entropyV,'like',Iarray); %for octave
entropyV = cast(entropyV,class(Iarray));

sizeV = sum(~isnan(Iarray));
for k = 1:size(Iarray,2)
edgeV = edgeMinV(k):binWidth:edgeMaxV(k); 
if any(~isnan(Iarray(:,k)))
%countV = histcounts(Iarray(:,k)+offsetForEntropyV(k),edgeV) + eps; 
countV = histc(Iarray(:,k)+offsetForEntropyV(k),edgeV) + eps;   %for octave
%-------%
%numGrLevels = 16; %For GRE calculation;
%countV = histcounts(Iarray(:,k)+offsetForEntropyV(k),numGrLevels); %For GRE calculation;
%--------%
probV = countV/sizeV(k);
entropyV(k) = - sum(probV .* log2(probV+eps));
else
entropyV(k) = NaN;
end
end
RadiomicsFirstOrderS.entropy = entropyV;

%   Root mean square (RMS)
RadiomicsFirstOrderS.rms           = sqrt(nansum((Iarray+offsetForEnergy).^2)./sizeV);

%   Energy ( integraal(a^2) )
RadiomicsFirstOrderS.energy   = nansum((Iarray+offsetForEnergy).^2);

%   Total Energy ( voxelVolume * integraal(a^2) )
RadiomicsFirstOrderS.totalEnergy   = nansum((Iarray+offsetForEnergy).^2) * VoxelVol;

%   Mean deviation (also called mean absolute deviation)
RadiomicsFirstOrderS.meanAbsDev            = mad(Iarray);

% Median absolute deviation
RadiomicsFirstOrderS.medianAbsDev = nansum(abs(Iarray-RadiomicsFirstOrderS.median))./sizeV;

%   P10 
%  (Note: prctile treats NaNs as missing values and removes them.)
p10 = prctile(Iarray,10);
RadiomicsFirstOrderS.P10 = p10;

%   P90
p90 = prctile(Iarray,90);
RadiomicsFirstOrderS.P90 = p90;

Iarray10_90 = Iarray;
idx10_90 = Iarray >= p10 & Iarray <= p90;
Iarray10_90(~idx10_90) = NaN;
idx10_90(isnan(idx10_90)) = 0;

%   Robust Mean Absolute Deviation
RadiomicsFirstOrderS.robustMeanAbsDev  = mad(Iarray10_90);

%   Robust Median Absolute Deviation
RadiomicsFirstOrderS.robustMedianAbsDev  = nansum(abs(Iarray10_90-nanmedian(Iarray10_90)))...
    ./ double(sum(idx10_90));

% Inter-Quartile Range (IQR)
% P75 - P25
p75 = prctile(Iarray,75);
p25 = prctile(Iarray,25);
RadiomicsFirstOrderS.interQuartileRange = p75 - p25;

% Quartile coefficient of Dispersion
RadiomicsFirstOrderS.coeffDispersion = (p75-p25)./(p75+p25+eps);

% Coefficient of variation
RadiomicsFirstOrderS.coeffVariation = RadiomicsFirstOrderS.std ./(RadiomicsFirstOrderS.mean + eps);


end