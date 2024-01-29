function [scale1V,scaledCPv] = calc_NTCPLimit(paramS,modelC,...
                                       scaleMode,maxDeltaFrx)   
% calc_NTCPLimit.m
% Returns scale factor at first violation
%-------------------------------------------------------------------------------
% AI 01/11/2020 

%Get structure names
structNumV =  paramS.structNum;
%Get num frx
nFrxProtocol = paramS.numFractions.val;
%Get DVH
doseBinsC = modelC.dv{1};
volHistC = modelC.dv{2};
%Get limit
limitV = modelC.limit;

%Define scale range
if scaleMode == 1
    xScaleV = linspace(0.5,1.5,100);
else
    rangeV = linspace(-maxDeltaFrx,maxDeltaFrx,2*maxDeltaFrx+1);
    rangeV = rangeV(rangeV+nFrxProtocol>=1);
    nfrxV = rangeV+nFrxProtocol;
    xScaleV = (nfrxV)/nFrxProtocol;
end


scaledCPv = xScaleV * 0;
for n = 1 : numel(xScaleV)
    
    %Compute scale factor
    scale = xScaleV(n);
    %Scale dose bins
    scaledDoseBinsC = cellfun(@(x) x*scale,doseBinsC,'un',0);
    %Fractionation correction
    if scaleMode == 1
        correctedScaledDoseC = frxCorrectROE(modelC,...
            structNumV,nFrxProtocol,scaledDoseBinsC);
    else
        correctedScaledDoseC = frxCorrectROE(modelC,...
            structNumV,nfrxV(n),scaledDoseBinsC);
    end
    %Compute TCP/NTCP
    if numel(structNumV)==1
        scaledCPv(n) = feval(modelC.function,...
            paramS,correctedScaledDoseC{1},volHistC{1});
    else
        scaledCPv(n) = feval(modelC.function,...
            paramS,correctedScaledDoseC,volHistC);
    end
    
end


%Record 1st violation of constraints
if ~isempty(limitV)
    violIdxV = inf(1,numel(limitV));
    if numel(limitV)==2 %For ranges
        %Compare against lower limit (guideline)
        isViolationV = scaledCPv > limitV(1);
        lowIdx = max(1,find(isViolationV,1,'first') - 1);
        if ~isempty(lowIdx)
            violIdxV(1) = lowIdx;
            scale1V(1) = xScaleV(lowIdx);
            if scale1V(1)<=1
                ind = find(xScaleV>1,1,'first');
                violIdxV(1) = ind;
                %Guideline only comes into effect on dose escalation
                scale1V(1) = xScaleV(ind);
            end
            %Compare against upper limit (hard constraint)
            isViolationV = scaledCPv > limitV(2);
            highIdx = max(1,find(isViolationV,1,'first') - 1);
            if ~isempty(highIdx)
                violIdxV(2) = highIdx;
                scale1V(2) = xScaleV(highIdx);
            else
                violIdxV(2) = inf;
                scale1V(2) = inf;
            end
        else
            scale1V = [inf inf];
        end
    else
        isViolationV = scaledCPv > modelC.limit;
        violIdxV = max(1,find(isViolationV,1,'first') - 1); %Changed
        if isempty(violIdxV)
            scale1V = inf;
        else
            scale1V = xScaleV(violIdxV);
        end
    end
else
    scale1V = inf;
end


end