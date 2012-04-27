function gammaM = gammaDose3d(doseArray1, doseArray2, deltaXYZv, dosePercent, distAgreement)
% function gammaM = gammaDose3d(doseArray1, doseArray2, deltaXYZv, dosePercent, distAgreement)
%
% APA, 04/27/2012

deltaX = deltaXYZv(1);
deltaY = deltaXYZv(1);
deltaZ = deltaXYZv(1);
incrementRadius = min([deltaX deltaY deltaZ]);

% Calculate until twice the permissible distance to agreement.
maxDistance = distAgreement*4;
outerRadiusV = incrementRadius:incrementRadius:maxDistance;
innerRadiusV = 0:incrementRadius:maxDistance-incrementRadius;

%
regu = 0;
gammaM = doseArray1 - doseArray2;
convergedM = gammaM.^2 <= regu^2;
gammaM(convergedM) = 0;

gammaM(~convergedM) = (100*(gammaM(~convergedM)./(doseArray1(~convergedM)+regu))/dosePercent).^2;

siz = size(gammaM);
minDoseRatioM = zeros(siz,'single');
maxDoseRatioM = minDoseRatioM;

for radNum = 1:length(outerRadiusV)
    
    disp('--- Iteraion ----')
    disp(radNum)
    
    outerRadius = outerRadiusV(radNum);    
    
    rowOutV = floor(outerRadius/deltaY);
    colOutV = floor(outerRadius/deltaX);
    slcOutV = floor(outerRadius/deltaZ);
        
    NHOOD_outer = createEllipsoidNHOOD(1:rowOutV,1:colOutV,1:slcOutV);
    
    % Compute Min and Max for the ellipsoid neighborhood
    [minLocalM, maxLocalM] = getMinMaxIM(doseArray2,NHOOD_outer);
    
    minDoseRatioM(~convergedM) = (100*(doseArray1(~convergedM)-minLocalM(~convergedM))./(doseArray1(~convergedM)+regu)).^2 / dosePercent^2;
    maxDoseRatioM(~convergedM) = (100*(doseArray1(~convergedM)-maxLocalM(~convergedM))./(doseArray1(~convergedM)+regu)).^2 / dosePercent^2;
    
    gammaM(~convergedM) = (min(minDoseRatioM(~convergedM),maxDoseRatioM(~convergedM)) + (outerRadius/distAgreement)^2).^0.5;
       
    convergedM = convergedM | minDoseRatioM <= 1 | maxDoseRatioM <= 1;    
    
    if all(convergedM(:))
        disp('All converged!!!')
        break
    end
    
end

gammaM = gammaM.^0.5;

