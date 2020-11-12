function paramS = calcSemiQuantParams(resampSigM,timeOutV,TTHPv,SHPv)
% paramS = calcSemiQuantParams(resampSigM,timeOutV,TTHPm,SHPm);
% ----------------------------------------------------------------
% INPUTS
% resampSigM : Relative signal enhancement (nVox x nTimePts)
% timeOutV   : (Resampled) time points
% TTHPm      : Time to half peak
% SHPm       : Signal at half-peak
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
%Gradient estimated by linear regression of all RSEs between 20% and 80% PE
cond_20v = bsxfun(@ge,relSigEnhM,.2*PEv);
[~,id_20v] = max(cond_20v,[],2);
cond_80v = bsxfun(@gt,relSigEnhM,.8*PEv);
[~,id_80v] = max(cond_80v,[],2);
id_80v = id_80v-1;
IGv = nan(nVox,1);
igIdxV = false(size(relSigEnhM));
for i = 1:nVox
    idxV = id_20v(i):id_80v(i);
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
        y = relSigEnhM(:,t0(i):t1(i)).';
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
paramS.PE = PEv;
paramS.TTP = TTPv;
paramS.TTHP = TTHPv;
paramS.SHP = SHPv;
paramS.WIS = WISv;
paramS.WOS = WOSv;
paramS.IG = IGv;
paramS.WOG = WOGv;
paramS.SER = SERv;
paramS.IAUC30 = IAUC30V;
paramS.IAUC60 = IAUC60V;
paramS.IAUC90 = IAUC90V;
paramS.IAUC120 = IAUC120V;
paramS.IAUC150 = IAUC150V;
paramS.IAUC180 = IAUC180V;
paramS.IAUCtthp = IAUCtthpV;
paramS.IAUCttp = IAUCttpV;

end