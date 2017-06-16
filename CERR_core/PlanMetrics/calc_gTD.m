function gTD = calc_gTD(doseBinsV,volV,paramS)
% function gTD = calc_gtD(doseBinsV,volV,paramS);
% This function returns the generalized tumor dose to the lung
% ----------- INPUTS -----------------------------------------------------
% paramS.treatmentSchedule.val
% paramS.alpha.val
% paramS.beta.val      
% paramS.refEQdose.val
% paramS.refVol.val;
% paramS.numFractions
% ----------------------------------------------------------------------------
% AI 6/6/17
% Based on Matlab code originally developed by Andrew Fontanella.
% ============================================================================

%% Get model parameters
treatmentSchedule = str2num(paramS.treatmentSchedule.val);
alpha = paramS.alpha.val;
beta = paramS.beta.val;
abRatio = alpha/beta;  
EQdose = paramS.refEQdose.val;
numFractions = paramS.numFractions.val; 
refVol = paramS.refVol.val;
q = -1;

%% Calc DVH matrix, tumor vol
DVHdoseInterval = 1;
doseValues = 0:DVHdoseInterval:ceil(max(doseBinsV));
fractionalVolV = volV./sum(volV);
DVHmatrix = zeros(1,length(doseValues));
for k = 1:length(doseValues)
        dose = doseBinsV(k);
        fractionalVol = fractionalVolV(k);
        doseIdx = round(dose*(1/DVHdoseInterval))+1;
        DVHmatrix(doseIdx) = DVHmatrix(doseIdx) + fractionalVol;
end
tumorVol = sum(DVHmatrix);

%%  Calculate cell viability per radiation dose for patients and reference
emptyDVHidx = ~logical(DVHmatrix);
dosePerFraction = doseValues/numFractions;
% Estimate min SF
[survivingFraction,~,~,~] = surviving_fraction_model(dosePerFraction,treatmentSchedule,alpha,abRatio,emptyDVHidx);
NaNSurvivingFraction = survivingFraction;
NaNSurvivingFraction(NaNSurvivingFraction == 0) = NaN;
minSurvivingFraction = 0.1*(tumorVol/refVol)*nanmin(NaNSurvivingFraction(:));
% Calc SF
[~,survivingFraction_t,t_vec,trt_pts] = surviving_fraction_model(EQdose,1,alpha,abRatio,0,minSurvivingFraction);
% Calc reference viable vol
Y = survivingFraction_t(logical(trt_pts));
X = t_vec(logical(trt_pts));
X = X(logical(Y));
Y = Y(logical(Y));
ii = find(trt_pts,length(X),'first');
t_vec = t_vec(1:ii(end));
Y_interp = exp(interp1(X,log(Y),t_vec));
refViableVolumeV = refVol*Y_interp;

%% Calc gTD
doseBinsFractionalVol = DVHmatrix/sum(DVHmatrix);
dosePrt = doseBinsFractionalVol.*survivingFraction.^q;
weightedViableVolume = tumorVol*(nansum(dosePrt)).^(1/q);
testVec = (refViableVolumeV > weightedViableVolume);
lastTimepointIdx = find(testVec,1,'last');
if lastTimepointIdx == length(testVec)
    error('Minimum reference viable volume exceeds viable tumor subvolume')
end
if isempty(lastTimepointIdx)
    trtTime = 0;
else
    trtTime = t_vec(lastTimepointIdx);
end
gTD = EQdose*trtTime/24;

