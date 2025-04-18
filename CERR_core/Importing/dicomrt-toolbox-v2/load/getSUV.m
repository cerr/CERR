function [suv3M,imageUnits] = getSUV(scan3M, headerS, suvType)
% function [suv3M,imageUnits] = getSUV(scan3M, headerS, suvType)
%
% This function calculates SUV for the passed suvType
%
% APA, 9/29/2020

scanSiz = size(scan3M);
suv3M = zeros(scanSiz);

% Obtain Start of acquisition time
numSlcs = size(scan3M,3);
acqTimeV = nan(numSlcs,1);
for slcNum = 1:numSlcs
    headerSlcS = headerS(slcNum);
    if isfield(headerSlcS,'acquisitionTime') && ~isempty(headerSlcS.acquisitionTime)
        acqTimeV(slcNum) = dcm_hhmmss(headerSlcS.acquisitionTime);
    end
end
seriesTime = dcm_hhmmss(headerSlcS.seriesTime);
seriesDate = NaN;
if isfield(headerSlcS,'seriesDate') && ~isempty(headerSlcS.seriesDate)
    seriesDate = datenum(headerSlcS.seriesDate,'yyyymmdd');
end
injectionDate = NaN;
if isfield(headerSlcS,'injectionDate') && ~isempty(headerSlcS.injectionDate)
    injectionDate = datenum(headerSlcS.injectionDate,'yyyymmdd');
end
acqStartTime = [];
if ~any(isnan(acqTimeV))
    acqStartTime = min(acqTimeV);
end

for slcNum = 1:size(scan3M,3)
    headerSlcS = headerS(slcNum);
    %headerSlcS = planC{indexS.scan}(scanNum).scanInfo(slcNum);
    %imgM = planC{indexS.scan}(scanNum).scanArray(:,:,slcNum);
    imgM = scan3M(:,:,slcNum)-headerSlcS.CTOffset;
    
    % Image Units
    imgUnits = headerSlcS.imageUnits;
    switch upper(imgUnits)
        case 'CNTS'
            activityScaleFactor = headerSlcS.petActivityConcentrationScaleFactor;
            imgM = imgM * activityScaleFactor;
            imgM = imgM * 1000; % Bq/L
        case {'BQML','BQCC'}
            % transformation to Bq/L.
            imgM = imgM * 1000; % 
        case {'KBQCC','KBQML'}
            % transform to Bq/L
            imgM = imgM * 1e6; % BQ/L
        otherwise
            error('SUV calculation is supported only for imageUnits BQML and CNTS')
    end    
    
    % Get Scan time based on type of decay correction
    decayCorrection = headerSlcS.decayCorrection;
    switch upper(decayCorrection)
        case 'START'
            scantime = seriesTime;
            if ~isempty(acqStartTime) && acqStartTime < scantime
                scantime = acqStartTime;                
            end
        case 'ADMIN'
            scantime = dcm_hhmmss(headerSlcS.injectionTime);
        case 'NONE'
            scantime = [];
        otherwise
            scantime = dcm_hhmmss(headerSlcS.petDecayCorrectionDateTime(9:end));
    end
    
    % Start Time for Radiopharmaceutical Injection
    injection_time = dcm_hhmmss(headerSlcS.injectionTime);
    
    if ~any(isnan([seriesDate,injectionDate]))
        injection_time = injection_time - (seriesDate-injectionDate)*24*3600;
    end
    
    % Half Life for Radionuclide
    half_life = headerSlcS.halfLife;
    
    % Total dose injected for Radionuclide
    injected_dose = headerSlcS.injectedDose;
    
    % Modality
    modality = headerSlcS.imageType;
    if strcmpi(modality,'NM SCAN')
        injected_dose = injected_dose * 1e6; % Convert MBq to Bq
    end
    
    % Fix issue where IOD is PT and injected_dose units are in MBq
    if injected_dose < 1e5
        injected_dose = injected_dose * 1e6;
    end    
    
    % Calculate the decay
    % The injected dose used to calculate suvM is corrected for the decay that
    % occurs between the time of injection and the time of scan.
    % decayFactor = e^(t1-t2/halflife);    
    if strcmpi(decayCorrection,'none')
        decay = 1;
    else
        decay = exp(-log(2)*(scantime-injection_time)/half_life);        
    end
    
    %Calculate the dose decayed during procedure
    injected_dose_decay = injected_dose*decay; % in Bq
    
    % Patient Weight
    ptWeight = headerSlcS.patientWeight;
    
    % Calculate SUV based on type
    % reference: http://dicom.nema.org/medical/Dicom/2017e/output/chtml/part16/sect_CID_85.html
    % SUVbw and SUVbsa equations are taken from Kim et al. Journal of Nuclear Medicine. Volume 35, No. 1, January 1994. pp 164-167.
    switch upper(suvType)
        case 'BW' % Body Weight
            suvM = imgM*ptWeight/injected_dose_decay; % pt weight in grams
            imageUnits = 'GML';
        case 'BSA' % body surface area
            % Patient height
            %(BSA in m2) = [(weight in kg)^0.425 \* (height in cm)^0.725 \* 0.007184].
            %SUV-bsa = (PET image Pixels) \* (BSA in m2) \* (10000 cm2/m2) / (injected dose).
            ptHeight = headerSlcS.patientSize; % units of meter
            bsaMm = ptWeight^0.425 * (ptHeight*100)^0.725 * 0.007184;
            suvM = imgM*bsaMm/injected_dose_decay;
            imageUnits = 'CM2ML';
        case 'LBM' %  % lean body mass by James method
            ptGender = headerSlcS.patientSex;
            ptHeight = headerSlcS.patientSize;
            if strcmpi(ptGender,'M')
                %LBM in kg = 1.10 \* (weight in kg) � 120 \* [(weight in kg) / (height in cm)]^2.
                lbmKg = 1.10 * ptWeight - 120 * (ptWeight/(ptHeight*100))^2;
                %1.10 * weight - 120 * (weight/height) ^2
            else
                %if d=gender == female
                %LBM in kg = 1.07 \* (weight in kg) � 148 \* [(weight in kg) / (height in cm)]^2.
                lbmKg = 1.07 * ptWeight - 148 * (ptWeight/(ptHeight*100))^2;
            end
            suvM = imgM*lbmKg/injected_dose_decay;
            imageUnits = 'GML';
        case 'LBMJAMES128' % lean body mass by James method
            imageUnits = 'GML';
        case 'LBMJANMA' % lean body mass by Janmahasatian method
            ptHeight = headerSlcS.patientSize;
            bmi = (ptWeight*2.20462 / (ptHeight*39.3701)^2) * 703;
            ptGender = headerSlcS.patientSex;
            if strcmpi(ptGender,'M')
                lbmKg = (9270 * ptWeight) / (6680 + 216*bmi); % male
            else
                lbmKg = (9270 * ptWeight) / (8780 + 244*bmi); % female
            end
            suvM = imgM*lbmKg/injected_dose_decay;
            imageUnits = 'GML';
        case 'IBW' % ideal body weight
            imageUnits = 'GML';
    end
    
    suv3M(:,:,slcNum) = suvM;
    
end
