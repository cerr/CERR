function gammaM = gammaDose3d(doseArray1, doseArray2, deltaXYZv, doseAgreement, distAgreement)
% function gammaM = gammaDose3d(doseArray1, doseArray2, deltaXYZv, doseAgreement, distAgreement)
%
% APA, 04/27/2012

deltaX = deltaXYZv(1);
deltaY = deltaXYZv(1);
deltaZ = deltaXYZv(1);
incrementRadius = min([deltaX deltaY deltaZ]);

% Initial gamma
gammaM = ((doseArray1-doseArray2).^2).^0.5/doseAgreement;
convergedM = false(size(gammaM));

% Calculate until 4 times the permissible distance to agreement.
maxDistance = distAgreement*4;
outerRadiusV = incrementRadius:incrementRadius:maxDistance;

siz = size(gammaM);
minDoseDiffM = zeros(siz,'single');
maxDoseDiffM = minDoseDiffM;

convergenceCountM = zeros(siz,'uint8');

for radNum = 1:length(outerRadiusV)
    
    disp(['--- Iteraion ', num2str(radNum), ' ----'])    
    
    % Create an ellipsoid ring neighborhood
    outerRadius = outerRadiusV(radNum);    
    
    rowOutV = floor(outerRadius/deltaY);
    colOutV = floor(outerRadius/deltaX);
    slcOutV = floor(outerRadius/deltaZ);
        
    NHOOD_outer = createEllipsoidNHOOD(1:rowOutV,1:colOutV,1:slcOutV);
    
    % Compute Min and Max for the ellipsoid neighborhood
    [minLocalM, maxLocalM] = getMinMaxIM(doseArray2,NHOOD_outer);
    
    % Compute difference between dose1 and (min,max) for dose2
    minDoseDiffM(~convergedM) = doseArray1(~convergedM) - minLocalM(~convergedM);
    maxDoseDiffM(~convergedM) = maxLocalM(~convergedM) - doseArray1(~convergedM);
    
    % If dose1 is contained within (min,max) for dose2, then it converged!
    newConvergedM = ~convergedM & minDoseDiffM >= 0 & maxDoseDiffM >= 0;
    
    % Compute gamma for voxels that converged
    gammaM(newConvergedM) =  min(gammaM(newConvergedM), outerRadius/distAgreement);
    
    % Add newly converged voxels to the list
    convergedM = convergedM | newConvergedM;    
    
    % Compute gamma for voxels that have not yet converged
    gammaForNotConvergedM =  (min((minDoseDiffM(~convergedM)-doseAgreement).^2, (maxDoseDiffM(~convergedM)-doseAgreement).^2)./doseAgreement^2 + (outerRadius/distAgreement)^2).^0.5;
    gammaM(~convergedM) = min(gammaM(~convergedM), gammaForNotConvergedM);
       
    % Count number of consecutive gamma increments for each uncoverged voxel
    indConvergeM = false(size(gammaM));
    indConvergeM(~convergedM) = gammaM(~convergedM) <= gammaForNotConvergedM;
    convergenceCountM(indConvergeM) = convergenceCountM(indConvergeM) + 1;
    
    % If gamma increases 4 consecutive times for a voxel, then assume it has converged
    convergedM(convergenceCountM > 3) = 1;
        
    if all(convergedM(:))
        disp('All converged!!!')
        break
    end
    
end

