function gammaM = createGammaDose(doseNum1,doseNum2,dosePercent,distAgreement)
% function gammaM = createGammaDose(doseNum1,doseNum2,dosePercent,distAgreement)
%
% This function creates and adds a gamma dose to planC.
% 3D Gamma is calculated between doseNum1 and doseNum2.
% dosePercent is the allowable fraction of doseNum1. 
% doseAgreement = max(doseNum1)*dosePercent/100;
% distAgreement is in cm.
%
% APA, 04/26/2012

global planC stateS
indexS = planC{end};

% Get deltaX, deltaY, deltaZ
[xDoseVals, yDoseVals, zDoseVals] = getDoseXYZVals(planC{indexS.dose}(doseNum1));
deltaX = abs(xDoseVals(2) - xDoseVals(1));
deltaY = abs(yDoseVals(2) - yDoseVals(1));
deltaZ = abs(zDoseVals(2) - zDoseVals(1));

doseAgreement = dosePercent*max(planC{indexS.dose}(doseNum1).doseArray(:))/100;
gammaM = gammaDose3d(planC{indexS.dose}(doseNum1).doseArray, planC{indexS.dose}(doseNum2).doseArray, [deltaX deltaY deltaZ], doseAgreement, distAgreement);

newDoseNum = length(planC{indexS.dose}) + 1;

planC{indexS.dose}(newDoseNum) = planC{indexS.dose}(doseNum1);

planC{indexS.dose}(newDoseNum).doseArray = gammaM;

planC{indexS.dose}(newDoseNum).doseUID = createUID('dose');

planC{indexS.dose}(newDoseNum).fractionGroupID = 'Gamma 3D';

stateS.doseSet = newDoseNum;
stateS.doseChanged = 1;
CERRRefresh
