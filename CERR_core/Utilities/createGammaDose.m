function gammaM = createGammaDose(doseNum1,doseNum2,dosePercent,distAgreement)
% function gammaM = createGammaDose(doseNum1,doseNum2,dosePercent,distAgreement)
%
% This function creates and adds a gamma dose to planC.
% 3D Gamma is calculated between doseNum1 and doseNum2.
% dosePercent is the dose criteria based on max(doseNum1). 
% doseAgreement = max(doseNum1)*dosePercent/100;
% distAgreement is in cm.
%
% APA, 04/26/2012

global planC stateS
indexS = planC{end};

% Prepare inputs for gamma calculation
[newXgrid, newYgrid, newZgrid, doseArray1, doseArray2] = prepareDosesForGamma(doseNum1,doseNum2,1, planC);



% % Get deltaX, deltaY, deltaZ
% [xDoseVals, yDoseVals, zDoseVals] = getDoseXYZVals(planC{indexS.dose}(doseNum1));
% deltaX = abs(xDoseVals(2) - xDoseVals(1));
% deltaY = abs(yDoseVals(2) - yDoseVals(1));
% deltaZ = abs(zDoseVals(2) - zDoseVals(1));

deltaX = abs(newXgrid(2) - newXgrid(1));
deltaY = abs(newYgrid(2) - newYgrid(1));
deltaZ = abs(newZgrid(2) - newZgrid(1));


doseAgreement = dosePercent*max(planC{indexS.dose}(doseNum1).doseArray(:))/100;
% gammaM = gammaDose3d(planC{indexS.dose}(doseNum1).doseArray, planC{indexS.dose}(doseNum2).doseArray, [deltaX deltaY deltaZ], doseAgreement, distAgreement);

gammaM = gammaDose3d(doseArray1, doseArray2, [deltaX deltaY deltaZ], doseAgreement, distAgreement);

newDoseNum = length(planC{indexS.dose}) + 1;

% planC{indexS.dose}(newDoseNum) = planC{indexS.dose}(doseNum1);
% 
% planC{indexS.dose}(newDoseNum).doseArray = gammaM;
% 
% planC{indexS.dose}(newDoseNum).doseUID = createUID('dose');
% 
% planC{indexS.dose}(newDoseNum).fractionGroupID = 'Gamma 3D';


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
planC{indexS.dose}(newDoseNum).fractionGroupID = 'Gamma 3D';

%Switch to new dose
sliceCallBack('selectDose', num2str(newDoseNum));


% stateS.doseSet = newDoseNum;
% stateS.doseChanged = 1;
% CERRRefresh
