function c = calcOMTDoseDistance(doseNum1,doseNum2,structNum,gamma,downsampleFactor,planC)
% function c = calcOMTDoseDistance(doseNum1,doseNum2,structNum,gamma,downsampleFactor,planC)
%
% Example:
% doseNum1 = 1;
% doseNum2 = 2;
% structNum = 1;
% gamma = 0.1;
% downsampleFactor = 1;
% c = calcOMTDoseDistance(doseNum1,doseNum2,structNum,gamma, downsampleFactor,planC)
%
% APA, 7/16/2021
% Based on code by Jieinig Zhu.

indexS = planC{end};

scanType = 'normal';
scanNum = getStructureAssociatedScan(structNum,planC);

% Get doseNum1 on CT grid
dose1M = getDoseOnCT(doseNum1, scanNum, scanType, planC);

% Get doseNum2 on CT grid
dose2M = getDoseOnCT(doseNum2, scanNum, scanType, planC);

% Get structre mask
struct3M = getStrMask(strNum,planC);

% Get structure bounding box
[rMin,rMax,cMin,cMax,sMin,sMax] = compute_boundingbox(struct3M);

% Crop doses
dose1M(~struct3M) = 0;
dose2M(~struct3M) = 0;
dose1M = dose1M(rMin:rMax,cMin:cMax,sMin:sMax);
dose2M = dose2M(rMin:rMax,cMin:cMax,sMin:sMax);

% Downsample if required
disp('Downsampling...')
disp(downsampleFactor)

% Get the voxel size (scan grid since dose is interpolated to scan grid)
[xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNum));
Hx = abs(xDoseV(cMax)-xValsV(cMin))/10;
Hy = abs(yDoseV(rMax)-yValsV(rMin))/10;
Hz = abs(zDoseV(sMax)-zValsV(sMin))/10;
H.Hx = Hx;
H.Hy = Hy;
H.Hz = Hz;

[c,s] = unbalance3d_dose_2(dose1M,dose2M,gamma,H,'n'); %unbalance3d_dose_n
