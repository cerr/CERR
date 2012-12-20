function gammaM = gammaScan3d(doseArray1, doseArray2, deltaXYZv, doseAgreement, distAgreement, maxDistance)
% function gammaM = gammaScan3d(doseArray1, doseArray2, deltaXYZv, doseAgreement, distAgreement, maxDistance)
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
if ~exist('maxDistance', 'var')
    maxDistance = distAgreement*1.5;
end
outerRadiusV = incrementRadius:incrementRadius:maxDistance;
numIters = length(outerRadiusV);

siz = size(gammaM);
minDoseDiffM = zeros(siz,'single');
maxDoseDiffM = minDoseDiffM;

% convergenceCountM = zeros(siz,'uint8');

% Update waitbar on gamma GUI
gammaGUIFig = findobj('tag','CERRgammaInputGUI');
if ~isempty(gammaGUIFig)
    ud = get(gammaGUIFig,'userdata');
    set(ud.wb.patch,'xData',[0 0 0 0])
end

for radNum = 1:numIters
    
    disp(['--- Gamma Calculation Iteraion ', num2str(radNum), ' ----'])    
    
    % Create an ellipsoid ring neighborhood
    outerRadius = outerRadiusV(radNum);    
    
    rowOutV = floor(outerRadius/deltaY);
    colOutV = floor(outerRadius/deltaX);
    slcOutV = floor(outerRadius/deltaZ);
        
    NHOOD_outer = createEllipsoidNHOOD(1:rowOutV,1:colOutV,1:slcOutV);
    
    % Compute Min and Max for the ellipsoid neighborhood
    [minLocalM, maxLocalM] = getMinMaxIM(doseArray2,NHOOD_outer);
    
    % Compute difference between dose1 and (min,max) for dose2
    minDoseDiffM(~convergedM) = doseArray1(~convergedM) - minLocalM(~convergedM) + doseAgreement; % D1-(min(D2)-5)
    maxDoseDiffM(~convergedM) = maxLocalM(~convergedM) + doseAgreement - doseArray1(~convergedM); % (max(D2)+5)-D1
    
    % If dose1 is contained within (min,max) for dose2, then it converged!
    newConvergedM = ~convergedM & minDoseDiffM >= 0 & maxDoseDiffM >= 0;
    
    % Compute gamma for voxels that converged
    %gammaM(newConvergedM) =  min(gammaM(newConvergedM), outerRadius/distAgreement);
    gammaM(newConvergedM) =  outerRadius;
    
    % Add newly converged voxels to the list
    convergedM = convergedM | newConvergedM;    
    
    % Compute gamma for voxels that have not yet converged
    %gammaForNotConvergedM =  (min((minDoseDiffM(~convergedM)-doseAgreement).^2, (maxDoseDiffM(~convergedM)-doseAgreement).^2)./doseAgreement^2 + (outerRadius/distAgreement)^2).^0.5;
    %gammaM(~convergedM) = min(gammaM(~convergedM), gammaForNotConvergedM);
       
    % If gamma is less or equal to outerRadius/distAgreement, then the voxel conveged!
    %convergedM(~convergedM) = gammaM(~convergedM) <= outerRadius/distAgreement;
    
    
    if ~isempty(gammaGUIFig)
        set(ud.wb.patch,'xData',[0 0 radNum/numIters radNum/numIters])
        drawnow
    end
        
    if all(convergedM(:))
        disp('All converged!!!')
        if ~isempty(gammaGUIFig)
            set(ud.wb.patch,'xData',[0 0 1 1])
        end
        break
    end
    
end

gammaM(~convergedM) = NaN;
