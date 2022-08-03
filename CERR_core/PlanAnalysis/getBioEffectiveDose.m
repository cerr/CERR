function effectiveDose3M = getBioEffectiveDose(dose3M,correctionType,alpha,beta,...
    numFractions,stdFractionSize)
% function effectiveDose3M = getBioEffectiveDose(dose3M,correctionType,alpha,beta,...
%     numFractions,stdFractionSize)
%
% % ========= Example usage ==========
%
% global planC
% indexS = planC{end};
% doseNum = 1;
% dose3M = planC{indexS.dose}(doseNum).doseArray;
% alpha = 3;
% beta = 1;
% planNum = getDoseAssociatedPlan(dose3M,planC);
% numFractions = planC{indexS.beams}(planNum).FractionGroupSequence.Item_1.NumberOfFractionsPlanned
%
% % ====== LQ correction =======
% correctionType = 'LQ';
% lqDose3M = getBioEffectiveDose(dose3M,correctionType,alpha,beta,...
%     numFractions);
%
% % ====== EQD2 correction =======
% correctionType = 'EQD';
% stdFractionSize = 2;
% lqDose3M = getBioEffectiveDose(dose3M,correctionType,alpha,beta,...
%     numFractions,stdFractionSize);
%
% APA, 7/15/2022

if strcmpi(correctionType,'LQ')
    
    effectiveDose3M = exp( -dose3M .* (alpha + beta*dose3M/numFractions) );
    
elseif strcmpi(correctionType,'EQD')
    
    fractionSize3M = dose3M / numFractions;
    
    abRatio = alpha / beta;
    
    % BED
    effectiveDose3M = dose3M .* ...
        (1+fractionSize3M/abRatio);
    
    % EQD2
    effectiveDose3M = effectiveDose3M / (1+stdFractionSize/abRatio);
    
end
