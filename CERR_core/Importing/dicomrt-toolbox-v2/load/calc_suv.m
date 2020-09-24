function suvM = calc_suv(headerS,imgM)
% suvM = calc_suv(headerS,imgM)
%
% Calcualtes SUV for the passed dicom header (headerS) and PET image
% imgM. 
%
% Input: 
% imgM must be in Bq/ml. 
%
% Output: 
% suvM will be in gm/ml
%
% Written IEN
% APA, 9/22/2020, updated to (1) get scan time based on deay correction,
% (2) checked imageUnits. 
%  References: http://www.turkupetcentre.net/petanalysis/model_suv.html
%              https://documentation.clearcanvas.ca/Documentation/UsersGuide/Personal/13_1/index.html?suv.htm

% Get Patient weight in grams
ptweight = headerS.patientWeight*1000; % in grams

if isempty(ptweight) || ptweight==0
    disp('Patient Weight is missing. suvM calculation ignored.');
    suvM=imgM;
    return
end

% Get Decay correction
correctedImage = headerS.correctedImage;
if ~any(ismember('DECY',correctedImage))
    disp('suvM calciulation is applicable only when petDecayCorrection = DECY');
    suvM = imgM;
    return
end

imageUnits = headerS.imageUnits;
switch upper(imageUnits)
    case 'BQML'
                
    otherwise
        disp('suvM calciulation not supported for ImaageUnits other than BQML');
        suvM = imgM;
        return;
        
        % 1 Ci = 3.7 x 1010 Bq = 37 GBq
        % 1 mCi = 3.7 x 107 Bq = 37 MBq
        % 1 µCi = 3.7 x 104 Bq = 37 kBq
        % 1 nCi = 37 Bq
end

% Get Scan time based on type of decay correction
decayCorrection = headerS.decayCorrection;
switch upper(decayCorrection)
    case 'START'
        scantime = dcm_hhmmss(headerS.seriesTime);
    case 'ADMIN'
        scantime = dcm_hhmmss(headerS.injectionTime);
    case 'NONE'
        scantime = dcm_hhmmss(headerS.acquisitionTime);
end

% Start Time for Radiopharmaceutical Injection
injection_time = dcm_hhmmss(headerS.injectionTime);

% Half Life for Radionuclide
half_life = headerS.halfLife;

% Total dose injected for Radionuclide
injected_dose = headerS.injectedDose;

% Calculate the decay
% The injected dose used to calculate suvM is corrected for the decay that
% occurs between the time of injection and the time of scan.
% decayFactor = e^(t1-t2/halflife);
decay = exp(-log(2)*(scantime-injection_time)/half_life);

%Calculate the dose decayed during procedure
injected_dose_decay = injected_dose*decay; % in Bq

% Calculate SUV.
suvM = imgM*ptweight/injected_dose_decay;

return
