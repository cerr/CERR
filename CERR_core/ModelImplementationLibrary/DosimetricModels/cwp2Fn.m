function prob = cwp2Fn(paramS,doseBinsC,volHistC)
% prob = cwp2Fn(paramS,doseBinsC,volHistC);
% ----------------------------------------------------------------------
% AI, 1/31/19 

%Extract parameters and corresponding weights 
[weight,x,parListC] = getParCoeff(paramS,'weight',doseBinsC,volHistC);

%Compute TCP/NTCP
constIdx = strcmpi(parListC,'constant');
gx = sum(weight(~constIdx).*x(~constIdx));
const = weight(constIdx).*x(constIdx);
prob = 1- exp(const*exp(gx));


%%--- Functions to extract model parameters and weights ----
    function [coeff,par,keepParC] = getParCoeff(paramS,fieldName,doseBinsC,volHistC)
        
        %Extract relevant parameters
        genFieldC = fields(paramS);
        for i = 1:numel(genFieldC)
            if strcmpi(genFieldC{i},'structures')
                structS = paramS.(genFieldC{i});
                structListC = fieldnames(structS);
                for j = 1:length(structListC)
                    strParamS = structS.(structListC{j});
                    strParamListC = fieldnames(strParamS);
                    for k = 1 : numel(strParamListC)
                        if isfield(strParamS.(strParamListC{k}),'cteg') |  isfield(strParamS.(strParamListC{k}),'weight')
                            parName = [structListC{j},strParamListC{k}];
                            keepParS.(parName) = strParamS.(strParamListC{k});
                        end
                    end
                end
            else
                 if isfield(paramS.(genFieldC{i}),'cteg') |  isfield(paramS.(genFieldC{i}),'weight')
                     parName = genFieldC{i};
                     keepParS.(parName) = paramS.(genFieldC{i});
                 end
            end
        end
      
       
       %Compute parameters, extract coefficients 
        keepParC = fieldnames(keepParS);
        numStr = 0;
        par = zeros(1,length(keepParC));
        coeff = zeros(1,length(keepParC));
        for n = 1:length(keepParC)
            coeff(n) = keepParS.(keepParC{n}).(fieldName);
            if isnumeric(keepParS.(keepParC{n}).val)
               par(n) = keepParS.(keepParC{n}).val;
            else
                if ~iscell(doseBinsC)  %For single-structure models
                    doseBinsV = doseBinsC;
                    volHistV = volHistC;
                else
                numStr = numStr+1;
                doseBinsV = doseBinsC{numStr};
                volHistV = volHistC{numStr};
                end
                if ~isfield(keepParS.(keepParC{n}),'params')
                    par(n) = eval([keepParS.(keepParC{n}).val,...
                        '(doseBinsV, volHistV)']);
                else
                    %Copy number fo fractions, abRatio
                    keepParS.(keepParC{n}).params.numFractions.val = paramS.numFractions;
                    if isfield(paramS,'abRatio')
                        keepParS.(keepParC{n}).params.abRatio.val = paramS.abRatio;
                    end
                    par(n) = eval([keepParS.(keepParC{n}).val,...
                        '(doseBinsV, volHistV,keepParS.(keepParC{n}).params)']);
                end
            end
        end
    end


end