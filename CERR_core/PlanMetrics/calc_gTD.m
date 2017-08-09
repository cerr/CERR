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
alpha = paramS.alpha.val;
beta = paramS.beta.val;
abRatio = alpha/beta;  
EQdose = paramS.refEQdose.val;
numFractions = paramS.numFractions.val; 
treatmentSchedule = 1 : numFractions+1;
refVol = paramS.refVol.val;
q = paramS.q.val;

%% Calculate DVH matrix, tumor volume
DVHdoseInterval = 1;
doseValues = 0:DVHdoseInterval:ceil(max(doseBinsV));
fractionalVolV = volV;
% ------------- FOR TESTING ---------------- %
%fractionalVolV = 75;
% ------------------------------------------ %
DVHmatrix = zeros(1,length(doseValues));
for k = 1:length(doseBinsV)
        dose = doseBinsV(k);
        fractionalVol = fractionalVolV(k);
        doseIdx = round(dose*(1/DVHdoseInterval))+1;
        DVHmatrix(doseIdx) = DVHmatrix(doseIdx) + fractionalVol;
end
tumorVol = sum(DVHmatrix);

%%  Calculate cell viability per radiation dose for patients and reference
emptyDVHidx = ~logical(DVHmatrix);
dosePerFraction = doseValues/numFractions;
% Calculate SF in tumor
[survivingFraction,~,~,~] = surviving_fraction_model(dosePerFraction,treatmentSchedule,alpha,abRatio,emptyDVHidx);
% Calculate SF in reference (hourly) for treatment schedule
NaNSurvivingFraction = survivingFraction;
NaNSurvivingFraction(NaNSurvivingFraction == 0) = NaN;
minSurvivingFraction = 0.1*(tumorVol/refVol)*nanmin(NaNSurvivingFraction(:)); % Estimate min SF
[~,survivingFraction_t,t_vec,trt_pts] = surviving_fraction_model(EQdose,1,alpha,abRatio,0,minSurvivingFraction); 

%% Compare reference viable volume (hourly) with tumor viable volume
% Calculate reference viable vol
Y = survivingFraction_t(logical(trt_pts));
X = t_vec(logical(trt_pts));
X = X(logical(Y));
Y = Y(logical(Y));
ii = find(trt_pts,length(X),'first');
t_vec = t_vec(1:ii(end));
Y_interp = exp(interp1(X,log(Y),t_vec));
refViableVolumeV = refVol*Y_interp;
% Calculate tumor viable vol
doseBinsFractionalVol = DVHmatrix/sum(DVHmatrix);
dosePrt = doseBinsFractionalVol.*survivingFraction.^q;
weightedViableVolume = tumorVol*(nansum(dosePrt)).^(1/q);
% Find last time point where reference viable vol > tumor viable vol
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

%% Calc gTD
% --- Modified expression -------%
%breaks = floor((trtTime/24)/7)*2;
%gTD = EQdose*(trtTime/24-breaks);
gTD = EQdose*trtTime/24;
% ------------------------------%

