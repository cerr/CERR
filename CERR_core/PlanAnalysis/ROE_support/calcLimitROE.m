function [cScale, critVal] = calcLimitROE(doseBinV,volHistV,critS,...
    numFrxProtocol,critNumFrx,abRatio,scaleFactorV)
% Calculate scale factor at which criteria are first violated
% AI 05/13/2021

cFunc =  critS.function;
cLim = critS.limit;
critVal = -inf;
count = 0;
s = 0;
while critVal <= cLim(1) && count<length(scaleFactorV)
    count = count + 1;
    %Scale dose bins
    s = scaleFactorV(count);
    scaledDoseBinsV = s*doseBinV;
    
    %Convert to standard no. fractions
    Na = numFrxProtocol;
    Nb = critNumFrx;
    a = Na;
    b = Na*Nb*abRatio;
    c = -scaledDoseBinsV.*(b + scaledDoseBinsV*Nb);
    correctedScaledDoseV = (-b + sqrt(b^2 - 4*a*c))/(2*a);
    
    if ~strcmp(cFunc,'ntcp')
        if isfield(critS,'parameters')
            cParamS = critS.parameters;
            critVal = feval(cFunc,correctedScaledDoseV,volHistV,cParamS);
        else
            critVal = feval(cFunc,correctedScaledDoseV,volHistV);
        end
    end
end
if s == max(scaleFactorV)
    cScale = inf;
    critVal = inf;
else
    cScale = s;
end
end