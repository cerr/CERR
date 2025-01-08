function paramS = calcSemiQuantParams(resampSigM,timeOutV,TTHPv,SHPv)
% paramS = calcSemiQuantParams(resampSigM,timeOutV,TTHPm,SHPm);
% ----------------------------------------------------------------
% INPUTS
% resampSigM : Relative signal enhancement (nVox x nTimePts)
% timeOutV   : (Resampled) time points
% TTHPm      : Time to half peak
% SHPm       : Signal at half-peak
% Ref.
% Lee, S.H., et al. (2017) "Correlation Between Tumor Metabolism and Semiquantitative Perfusion
% MRI Metrics in Non–small Cell Lung Cancer." IJROBP 99.2:S83-S84.
% ----------------------------------------------------------------
% AI 11/12/2020

%% Get relative signal enhancement
relSigEnhM = resampSigM - 1;
nVox = size(relSigEnhM,1);

%% Calc. parameters
%1. Peak enhancement (PE)
[PEv,peakIdxV] =  max(relSigEnhM,[],2); %PE = Peak RSE

%2 . Time-to-peak (TTP)
TTPv = timeOutV(1,peakIdxV).';

%3. Wash-in slope (WIS)
WISv = PEv./(TTPv+eps); % WIS = PE/TTP

%4. Wash-out slope (WOS)
Tend = timeOutV(end);
RSEendV = relSigEnhM(:,end);
peakAtEndIdx = TTPv == Tend;
WOSv = (PEv - RSEendV)./(TTPv - Tend); %WOS = (PE - RSE(Tend)) /(TTP – Tend),
%if PE does not occur at Tend
WOSv(peakAtEndIdx) = 0;                %Otherwise set to zero.

%5. Initial gradient (IG)
%Gradient estimated by linear regression of all RSEs between 10% and 70% PE
%cond_10v = bsxfun(@ge,relSigEnhM,.1*PEv);
%[~,id_10v] = max(cond_10v,[],2);
% cond_70v = bsxfun(@gt,relSigEnhM,.7*PEv);
% [~,id_70v] = max(cond_70v,[],2);
[~,id_10v] = min(abs(relSigEnhM - .1*PEv));
[~,id_70v] = min(abs(relSigEnhM - .7*PEv));
IGv = nan(nVox,1);
igIdxV = false(size(relSigEnhM));
for i = 1:nVox
    idxV = id_10v(i):id_70v(i);
    y = relSigEnhM(i,idxV).';
    x = [ ones(length(idxV),1) , timeOutV(idxV).'];
    b = x\y;
    IGv(i) = b(2);
    igIdxV(i,idxV) = true;
end

%Washout gradient (WOG)
%Gradient calculated by linear regression of RSE between PE and 1 min after PE
t0 = peakIdxV;
t1IdxM = double(timeOutV>=(timeOutV(t0).'+1));
skipRowV = ~any(t1IdxM.');
[~,t1] = max(t1IdxM,[],2);
t1(skipRowV) = nan;
WOGv = nan(nVox,1);
for i = 1:nVox
    if ~isnan(t1(i))
        x = [ ones(t1(i)-t0(i)+1,1),timeOutV(t0(i):t1(i)).'];
        y = relSigEnhM(i, t0(i):t1(i)).';
        b = x\y;
        WOGv(i) = b(2);
    else
        WOGv(i) = nan;
    end
end

%Signal enhancement ratio
tse1 = find(timeOutV>=.5,1,'first');
tse2 = find(timeOutV>=2.5,1,'first');
SERv = (relSigEnhM(:,tse1)./relSigEnhM(:,tse2));


%IAUC
% IAUCt = Integrated area under the RSE curve up to time 't'
IAUCv = cumtrapz(timeOutV.',relSigEnhM.');
IAUCtthpV = nan(1,nVox);
IAUCttpV = nan(1,nVox);
for i = 1:nVox
    IAUCtthpV(i) = IAUCv(find(timeOutV>=TTHPv(i),1,'first'),i);
    IAUCttpV(i) = IAUCv(find(timeOutV>=TTPv(i),1,'first'),i);
end
IAUC30V = IAUCv(find(timeOutV>.5,1,'first'),:);  %IAUC at t=30s
IAUC60V = IAUCv(find(timeOutV>1,1,'first'),:);   %IAUC at t=60s
IAUC90V = IAUCv(find(timeOutV>1.5,1,'first'),:); %IAUC at t=90s
IAUC120V = IAUCv(find(timeOutV>2,1,'first'),:);  %IAUC at t=120s
IAUC150V = IAUCv(find(timeOutV>2.5,1,'first'),:);%IAUC at t=150s
IAUC180V = IAUCv(find(timeOutV>3,1,'first'),:);  %IAUC at t=180s

% Create parameter dictionary
paramS.PeakEnhancement = PEv;
paramS.TimeToPeak = TTPv;
paramS.TimeToHalfPeak = TTHPv;
paramS.SignalAtHalfPeak = SHPv;
paramS.WashInSlope = WISv;
paramS.WashOutSlope = WOSv;
paramS.InitialGradient = IGv;
paramS.WashOutGradient = WOGv;
paramS.SignalEnhancementRatio = SERv;
paramS.IAUC30 = IAUC30V;
paramS.IAUC60 = IAUC60V;
paramS.IAUC90 = IAUC90V;
paramS.IAUC120 = IAUC120V;
paramS.IAUC150 = IAUC150V;
paramS.IAUC180 = IAUC180V;
paramS.IAUCtthp = IAUCtthpV;
paramS.IAUCttp = IAUCttpV;

end