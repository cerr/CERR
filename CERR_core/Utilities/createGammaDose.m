function gammaM = createGammaDose(doseNum1,doseNum2,strNum,doseAgreement,...
    distAgreement,thresholdPercentMax,maxDistanceFactor,doseDiffMethod,planC)
% function gammaM = createGammaDose(doseNum1,doseNum2,strNum,...
% doseAgreement,distAgreement,thresholdPercentMax,maxDistanceFactor,doseDiffMethod,planC);
%
% This function creates and adds a gamma dose to planC.
% 3D Gamma is calculated between doseNum1 and doseNum2.
% dosePercent is the dose criteria based on max(doseNum1). 
% doseAgreement = max(doseNum1)*dosePercent/100;
% distAgreement is in cm.
%
% APA, 04/26/2012

if ~exist('planC','var')
    global planC
end
    
indexS = planC{end};

% Prepare inputs for gamma calculation
assocScan = getDoseAssociatedScan(doseNum1,planC);
if isempty(assocScan)
    assocScan = 1;
end
[newXgrid, newYgrid, newZgrid, doseArray1, doseArray2, interpMask3M] = ...
    prepareDosesForGamma(doseNum1,doseNum2,strNum,assocScan,planC);

deltaX = abs(newXgrid(2) - newXgrid(1));
deltaY = abs(newYgrid(2) - newYgrid(1));
deltaZ = abs(newZgrid(2) - newZgrid(1));

if doseDiffMethod == 1
    doseAgreement = doseAgreement*max(planC{indexS.dose}(doseNum1).doseArray(:))/100;
end

thresholdAbsolute = thresholdPercentMax*max(planC{indexS.dose}(doseNum1).doseArray(:))/100;

maxCalcDistance = distAgreement * maxDistanceFactor;

gammaM = gammaDose3d(doseArray1, doseArray2, interpMask3M, ...
    [deltaX deltaY deltaZ], doseAgreement, distAgreement, ...
    maxCalcDistance, thresholdAbsolute, doseDiffMethod);

% Assume doses within the filter threshold pass gamma
%gammaM(isnan(gammaM)) = 0;

newDoseNum = length(planC{indexS.dose}) + 1;

%Remove old caching info.
planC{indexS.dose}(newDoseNum).cachedMask = [];
planC{indexS.dose}(newDoseNum).cachedColor = [];
planC{indexS.dose}(newDoseNum).cachedTime = [];

%Set coordinates.
planC{indexS.dose}(newDoseNum).sizeOfDimension1 = length(newXgrid);
planC{indexS.dose}(newDoseNum).sizeOfDimension2 = length(newYgrid);
planC{indexS.dose}(newDoseNum).sizeOfDimension3 = length(newZgrid);
planC{indexS.dose}(newDoseNum).horizontalGridInterval = newXgrid(2)-newXgrid(1);
planC{indexS.dose}(newDoseNum).verticalGridInterval = newYgrid(2)-newYgrid(1);
planC{indexS.dose}(newDoseNum).depthGridInterval = newZgrid(2)-newZgrid(1);
planC{indexS.dose}(newDoseNum).coord1OFFirstPoint = newXgrid(1);
planC{indexS.dose}(newDoseNum).coord2OFFirstPoint = newYgrid(1);
planC{indexS.dose}(newDoseNum).coord3OfFirstPoint = newZgrid(1);
planC{indexS.dose}(newDoseNum).zValues = newZgrid;
planC{indexS.dose}(newDoseNum).doseUnits = 'Gy';
planC{indexS.dose}(newDoseNum).doseArray = gammaM;
planC{indexS.dose}(newDoseNum).doseUID = createUID('dose');
strName = planC{indexS.structures}(strNum).structureName;
planC{indexS.dose}(newDoseNum).fractionGroupID = ['Gamma_',...
    num2str(doseAgreement),'%_',num2str(distAgreement*10),'mm','_',strName];

%Switch to new dose
sliceCallBack('selectDose', num2str(newDoseNum));

