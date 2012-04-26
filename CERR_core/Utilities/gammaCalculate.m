function [gammaM,convergedM] = gammaCalculate(doseNum1,doseNum2,dosePercent,distAgreement)
% function gammaM = gammaCalculate(doseNum1,doseNum2,dosePercent,distAgreement)
%
% APA, 04/26/2012

global planC
indexS = planC{end};

% Get deltaX, deltaY, deltaZ
[xDoseVals, yDoseVals, zDoseVals] = getDoseXYZVals(planC{indexS.dose}(doseNum1));

deltaX = abs(xDoseVals(2) - xDoseVals(1));
deltaY = abs(yDoseVals(2) - yDoseVals(1));
deltaZ = abs(zDoseVals(2) - zDoseVals(1));

incrementRadius = min([deltaX deltaY deltaZ]);

% Calculate until twice the permissible distance to agreement.
maxDistance = distAgreement*2;
outerRadiusV = incrementRadius:incrementRadius:maxDistance;
innerRadiusV = 0:incrementRadius:maxDistance-incrementRadius;

%
gammaM = planC{indexS.dose}(doseNum1).doseArray - planC{indexS.dose}(doseNum2).doseArray;
gammaM = gammaM.^2/dosePercent^2;

convergedM = gammaM < 1e-4; % less than 1e-4 difference acceptable? or make it even smaller

for radNum = 1:length(outerRadiusV)
    
    disp('--- Iteraion ----')
    disp(radNum)
    
    outerRadius = outerRadiusV(radNum);    
    innerRadius = innerRadiusV(radNum);
    
    rowOutV = floor(outerRadius/deltaY);
    colOutV = floor(outerRadius/deltaX);
    slcOutV = floor(outerRadius/deltaZ);
    
    % Make it run faster by using a ring
    rowInV = round(innerRadius/deltaY);
    colInV = round(innerRadius/deltaX);
    slcInV = round(innerRadius/deltaZ);
    
    NHOOD_outer = createEllipsoidNHOOD(1:rowOutV,1:colOutV,1:slcOutV);
    
    % Compute Min and Max for the ellipsoid neighborhood
    [minLocalM, maxLocalM] = getMinMaxIM(planC{indexS.dose}(doseNum2).doseArray,NHOOD_outer);
    
    newConvergedM = ~convergedM & (planC{indexS.dose}(doseNum1).doseArray >= minLocalM & planC{indexS.dose}(doseNum1).doseArray <= maxLocalM);
    
    newNotConvergedM = ~convergedM & ~(planC{indexS.dose}(doseNum1).doseArray >= minLocalM & planC{indexS.dose}(doseNum1).doseArray <= maxLocalM);

    convergedM = convergedM | newConvergedM;
    
    gammaM(newConvergedM) = (outerRadius/distAgreement)^2;   
    
    gammaM(newNotConvergedM) = min(((planC{indexS.dose}(doseNum1).doseArray(newNotConvergedM)-minLocalM(newNotConvergedM)).^2), (planC{indexS.dose}(doseNum1).doseArray(newNotConvergedM)-maxLocalM(newNotConvergedM)).^2)./(planC{indexS.dose}(doseNum1).doseArray(newNotConvergedM)).^2*100/dosePercent^2 + (outerRadius/distAgreement)^2;
    
    if all(convergedM(:))
        disp('All converged!!!')
        break
    end
    
end


gammaM = gammaM.^0.5;

newDoseNum = length(planC{indexS.dose}) + 1;

planC{indexS.dose}(newDoseNum) = planC{indexS.dose}(doseNum1);

planC{indexS.dose}(newDoseNum).doseArray = gammaM;

planC{indexS.dose}(newDoseNum).doseUID = createUID('dose');

planC{indexS.dose}(newDoseNum).fractionGroupID = 'Gamma 3D';

