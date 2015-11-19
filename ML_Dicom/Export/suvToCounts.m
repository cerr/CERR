function counts3M = suvToCounts(scanNum, planC)
% SUV=calc_suv(dicomhd,slice)
%
% Calcualtes the Counts from the passed scanNum for the PET scan
%
%Written APA, 8/31/2015

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

% Get the dicom header stored in planC
dicomhd = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders;

% Get Patient weight in grams
if isfield(dicomhd,'PatientWeight')
    ptweight = dicomhd.PatientWeight*1000;  % in grams
elseif isfield(dicomhd,'PatientsWeight')
     ptweight = dicomhd.PatientsWeight*1000;  % in grams
else
    disp('Patient Weight not found. Cannot convert to counts.')
    counts3M = planC{indexS.scan}(scanNum).scanArray;
    return    
end

if isempty(ptweight) || ptweight==0
    disp('Patient Weight is missing. Cannot convert to counts.');
    counts3M = planC{indexS.scan}(scanNum).scanArray;
    return
end

% Get Scan time
scantime = dcm_hhmmss(dicomhd.AcquisitionTime);

% Get calibration factor which is the Rescale slope Attribute Name in DICOM
calibration_factor = dicomhd.RescaleSlope;

% intercept=dicomhd.RescaleIntercept; Not Used

% Start Time for the Radiopharmaceutical Injection
injection_time = dcm_hhmmss(dicomhd.RadiopharmaceuticalInformationSequence.Item_1.RadiopharmaceuticalStartTime);
% Half Life for Radionuclide
half_life = dicomhd.RadiopharmaceuticalInformationSequence.Item_1.RadionuclideHalfLife;
% Total dose injected for Radionuclide
injected_dose = dicomhd.RadiopharmaceuticalInformationSequence.Item_1.RadionuclideTotalDose;

% Calculate the decay
%   decayFactor = e^(t1-t2/halflife);
decay = exp(-log(2)*(scantime-injection_time)/half_life);
%Calculate the dose decayed during procedure
injected_dose_decay = injected_dose*decay; % in Bq

% Calculate SUV.
% SUV  = (2DSlice x Calibration factor x Patient Weight) / Dose after decay
% SUV=slice*calibration_factor*ptweight/injected_dose_decay;
%SUV=slice*ptweight/injected_dose_decay; % NOTE that the "slice" coming in already has the calibration factor.
counts3M = planC{indexS.scan}(scanNum).scanArray * injected_dose_decay / ptweight; % / calibration_factor;
return
