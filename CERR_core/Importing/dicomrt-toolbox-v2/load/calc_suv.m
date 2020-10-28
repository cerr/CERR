function planC = calc_suv(scanNum,planC,suvType)
%function suvM = calc_suv(scanNum,planC,suvType)
%
% Calcualtes SUV for the passed scanNum and suvType.
%
% Input:
% planC{indexS.scan}(scanNum).scanArray must be in Bq/ml.
%
% Output:
% planC{indexS.scan}(scanNum).scanArray will be in gm/ml
% planC{indexS.scan}(scanNum).scanInfo.imageUnits and 
% planC{indexS.scan}(scanNum).scanInfo.suvType fields will be updated.
%
% Written IEN
% APA, 9/22/2020, updated to (1) get scan time based on deay correction,
% (2) checked imageUnits.
%  References: http://www.turkupetcentre.net/petanalysis/model_suv.html
%              https://documentation.clearcanvas.ca/Documentation/UsersGuide/Personal/13_1/index.html?suv.htm
% APA, 9/29/2020, updated to handle suvType

indexS = planC{end};

% Check required fields based on 1st slice
headerS = planC{indexS.scan}(scanNum).scanInfo(1);

% Check Patient weight
ptweight = headerS.patientWeight; % in grams
if isempty(ptweight) || ptweight==0
    disp('Patient Weight is missing. suvM calculation ignored.');
    return
end
%ptweight = ptweight * 1000; % in grams

% Check Decay correction
correctedImage = headerS.correctedImage;
if ~any(ismember('DECY',correctedImage))
    disp('SUV calciulation is applicable only when petDecayCorrection = DECY');
    return
end

imageUnits = headerS.imageUnits;
if ~any(ismember(imageUnits,{'BQML','CNTS'}))
    disp('SUV calciulation is applicable only when image units = BQML or CNTS');
    return
end
% 1 Ci = 3.7 x 1010 Bq = 37 GBq
% 1 mCi = 3.7 x 107 Bq = 37 MBq
% 1 µCi = 3.7 x 104 Bq = 37 kBq
% 1 nCi = 37 Bq

scan3M = planC{indexS.scan}(scanNum).scanArray;
headerS = planC{indexS.scan}(scanNum).scanInfo;
[suv3M,imageUnits] = getSUV(scan3M, headerS, suvType);
for slcNum = 1:size(planC{indexS.scan}(scanNum).scanArray,3)
    planC{indexS.scan}(scanNum).scanInfo(slcNum).imageUnits = imageUnits;
    planC{indexS.scan}(scanNum).scanInfo(slcNum).suvType = upper(suvType);
    planC{indexS.scan}(scanNum).scanArray(:,:,slcNum) = suv3M(:,:,slcNum);    
end
planC = setUniformizedData(planC,[],scanNum);

return
