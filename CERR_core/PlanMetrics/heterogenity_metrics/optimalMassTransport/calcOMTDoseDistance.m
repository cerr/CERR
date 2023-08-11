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
struct3M = getStrMask(structNum,planC);

% Get structure bounding box
[rMin,rMax,cMin,cMax,sMin,sMax] = compute_boundingbox(struct3M);

% Crop doses
dose1M(~struct3M) = 0;
dose2M(~struct3M) = 0;
dose1M = dose1M(rMin:rMax,cMin:cMax,sMin:sMax);
dose2M = dose2M(rMin:rMax,cMin:cMax,sMin:sMax);

% Downsample if required
[xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNum));

if downsampleFactor~=1
    
    disp('Downsampling...')
    disp(downsampleFactor)
    
    xValsV = xValsV(cMin:cMax);
    yValsV = yValsV(rMin:rMax);
    zValsV = zValsV(sMin:sMax);
    
    xResampleV = linspace(xValsV(1),xValsV(end),ceil(length(xValsV)/downsampleFactor));
    yResampleV = linspace(yValsV(1),yValsV(end),ceil(length(yValsV)/downsampleFactor));
    zResampleV = linspace(zValsV(1),zValsV(end),ceil(length(zValsV)));
    
    resampDose1M = imgResample3d(dose1M,xValsV,yValsV,zValsV,...
        xResampleV,yResampleV,zResampleV,'linear');
    resampDose2M = imgResample3d(dose2M,xValsV,yValsV,zValsV,...
        xResampleV,yResampleV,zResampleV,'linear');
    
    disp('done downsampling.')
else
    resampDose1M = dose1M;
    resampDose2M = dose2M;
end


% Get the voxel size (scan grid since dose is interpolated to scan grid)
[xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNum));
Hx = abs(xValsV(cMax)-xValsV(cMin))/10;
Hy = abs(yValsV(rMax)-yValsV(rMin))/10;
Hz = abs(zValsV(sMax)-zValsV(sMin))/10;
H.Hx = Hx;
H.Hy = Hy;
H.Hz = Hz;

[c,s] = unbalance3d_dose_2(resampDose1M,resampDose2M,gamma,H,'n'); %unbalance3d_dose_n
