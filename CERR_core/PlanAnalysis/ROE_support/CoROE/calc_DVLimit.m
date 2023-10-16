function [cScale,cValV,cValRx] = calc_DVLimit(doseBinV,volHistV,critS,...
    planNumFrx,stdNumFractions,abRatio,scaleMode,maxDeltaFrx,nFrxProtocol)
% calc_DVLimit.m
% Returns scale at first violation of dose-vol criteria/guidelines
%-------------------------------------------------------------------------------
% AI 01/11/2020     
    
%Get dose/volume metric
cFunc = critS.function;
%Get constraint
cLim = critS.limit;
%Define parameters for fractionation correction
Nb = stdNumFractions;
%Define scale range
if scaleMode == 1
    xScaleV = linspace(0.5,1.5,100);
else
    rangeV = linspace(-maxDeltaFrx,maxDeltaFrx,2*maxDeltaFrx+1);
    rangeV = rangeV(rangeV+nFrxProtocol>=1);
    nFrxV = rangeV+nFrxProtocol;
    xScaleV = nFrxV/nFrxProtocol;
end
cValV = 0*xScaleV;


%Identify limits
for scale = 1:numel(xScaleV)
    %Scale dose bins
    s = xScaleV(scale);
    scaledDoseBinsV = s*doseBinV;
    %Convert to standard no. fractions
    if scaleMode == 1
        Na = planNumFrx;
    else
        Na = nFrxV(scale);
    end
    a = Na;
    b = Na*Nb*abRatio;
    c = -scaledDoseBinsV.*(b + scaledDoseBinsV*Nb);
    correctedScaledDoseV = (-b + sqrt(b^2 - 4*a*c))/(2*a);
    
    if isfield(critS,'parameters')
        cParamS = critS.parameters;
        cValV(scale) = feval(cFunc,correctedScaledDoseV,volHistV,cParamS);
    else
        cValV(scale) = feval(cFunc,correctedScaledDoseV,volHistV);
    end
    
end

cValRx = [];
cScale = inf;
cIdx = cValV>cLim(1);
if any(cIdx)
    
    if critS.isGuide 
    %Guidelines only come into effect on dose escalation
        
        ind = find(cIdx,1,'first');
        
        if xScaleV(ind)<=1
            %Ignore guideline violations below prescription
            ind = find(xScaleV>1,1,'first');
            cScale = xScaleV(ind);
            
            %Check if guideline violated at prescription
            if numel(cLim)==2
                if scaleMode==0
                    Na = nFrxV(xScaleV==1);
                end
                a = Na;
                b = Na*Nb*abRatio;
                c = -doseBinV.*(b + doseBinV*Nb);
                correctedScaledDoseV = (-b + sqrt(b^2 - 4*a*c))/(2*a);
                if isfield(critS,'parameters')
                    cParamS = critS.parameters;
                    cValRx = feval(cFunc,correctedScaledDoseV,volHistV,cParamS);
                else
                    cValRx = feval(cFunc,correctedScaledDoseV,volHistV);
                end
                
                %ind = find(xScaleV==1-0.005);
                if cValRx > cLim(2) 
                    %cIdx = ind;
                    cScale = 1; 
                end
                
            else
                %Ignore guideline violations below prescription
                ind = find(xScaleV>1,1,'first');
                cScale = xScaleV(ind);
            end
            
        else
            %Apply guidelines above prescription
            cIdx = max(1,ind-1);
            cScale = xScaleV(cIdx); 
        end
        
    else %Apply hard constraints
        cIdx = max(1,find(cIdx,1,'first')-1);
        cScale = xScaleV(cIdx); 
    end
    
end


end