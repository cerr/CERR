function [RadiomicsFirstOrderS] = radiomics_first_order_stats(planC,structNum,doseNum)
%
% function [RadiomicsFirstOrder] = radiomics_first_order_stats(Data,Step)
%
% User defined radiomics metric
%
%   First Order Gray level statistics
%
%   Step is size of the bins bins (CT step is 10 HU)
%--------------------------------------------------------------------------
%   08/11/2010, Ralph Leijenaar
%   - added Mean deviation
%  10/13/2017 Modified to handle matrix input (planC)
%  Eg: RadiomicsFirstOrderS = radiomics_first_order_stats(dataM);
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
    
    % % Get Pixel-size
    % [xUnifV, yUnifV, zUnifV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
    % PixelSpacingXi = abs(xUnifV(2)-xUnifV(1));
    % PixelSpacingYi = abs(yUnifV(2)-yUnifV(1));
    % PixelSpacingZi = abs(zUnifV(2)-zUnifV(1));
    % VoxelVol = PixelSpacingXi*PixelSpacingYi*PixelSpacingZi;
    
    % Iarray = Data.Image(~isnan(Data.Image));     %    Array of Image values
    indStructV = maskStruct3M(:) == 1;
    Iarray = maskScan3M(indStructV);
    
else
    
    Iarray = planC;
    % VoxelVol = structNum;
end


% Calculate standard PET parameters
RadiomicsFirstOrderS.min           = min(Iarray);
RadiomicsFirstOrderS.max           = max(Iarray);
RadiomicsFirstOrderS.mean          = mean(Iarray);
RadiomicsFirstOrderS.range         = range(Iarray);
RadiomicsFirstOrderS.std           = std(Iarray,1);
RadiomicsFirstOrderS.var           = var(Iarray,1);
RadiomicsFirstOrderS.median        = median(Iarray);

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
N = ceil( RadiomicsFirstOrderS.range/Step);  %
%RadiomicsFirstOrder.entropy       = entropy_radiomics(Iarray,N);

% J = entropyfilt(varargin); % Misschien voor long, waar zit de hoogste
% heterogeniteit?

%   Root mean square (RMS)
RadiomicsFirstOrderS.rms           = sqrt(sum(Iarray.^2)/length(Iarray));

%   Total Energy ( integraal(a^2) )
RadiomicsFirstOrderS.totalEnergy   = sum(Iarray.^2);

%   Mean deviation (also called mean absolute deviation)
RadiomicsFirstOrderS.meanAbsDev            = mad(Iarray);

% Median absolute deviation
RadiomicsFirstOrderS.medianAbsDev = sum(abs(Iarray-RadiomicsFirstOrderS.median)) / numel(Iarray);

%   P10
p10 = prctile(Iarray,10);
RadiomicsFirstOrderS.P10 = p10;

%   P90
p90 = prctile(Iarray,90);
RadiomicsFirstOrderS.P90 = p90;

Iarray10_90 = Iarray;
idx10_90 = Iarray >= p10 & Iarray <= p90;
Iarray10_90(~idx10_90) = NaN;

%   Robust Mean Absolute Deviation
RadiomicsFirstOrderS.robustMeanAbsDev  = mad(Iarray10_90);

%   Robust Median Absolute Deviation
RadiomicsFirstOrderS.robustMedianAbsDev  = nansum(abs(Iarray10_90-nanmedian(Iarray10_90)))...
    ./ sum(idx10_90);

% Inter-Quartile Range (IQR)
% P75 - P25
p75 = prctile(Iarray,75);
p25 = prctile(Iarray,25);
RadiomicsFirstOrderS.interQuartileRange = p75 - p25;

% Quartile coefficient of Dispersion
RadiomicsFirstOrderS.coeffDispersion = (p75-p25)./(p75+p25);

% Coefficient of variation
RadiomicsFirstOrderS.coeffVariation = RadiomicsFirstOrderS.std ./ RadiomicsFirstOrderS.mean;


end