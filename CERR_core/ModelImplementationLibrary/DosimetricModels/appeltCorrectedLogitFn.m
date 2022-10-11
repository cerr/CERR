function prob = appeltCorrectedLogitFn(paramS,doseBinsC,volHistC)
% function prob = appeltCorrectedLogitFn(paramS,doseBinsC,volHistC);
% INPUTS
% paramS : Dictionary of model parameters
% Modifications for risk factors are computed based on Appelt et al.

%AI 10/8/18 

if iscell(doseBinsC)
    doseBinsV = doseBinsC{1};
else
    doseBinsV = doseBinsC;
end
if iscell(volHistC)
    volHistV = volHistC{1};
else
    volHistV = volHistC;
end

%Apply Appelt modification to D50, gamma50 for at-risk group
if isfield(paramS,'appeltMod') && strcmpi(paramS.appeltMod.val,'yes')
    %Get D50_0, gamma50_0
    D50_0 = paramS.D50_0.val;
    gamma50_0 = paramS.gamma50_0.val;
    %Get ORs
    [or,weight] = getParCoeff(paramS,'OR',doseBinsV,volHistV);
    orMult = or(weight==1);
    OR = prod(orMult);
    %Get modified D50, gamma50
    [D50, gamma50] = appeltMod(D50_0,gamma50_0,OR);
else
    D50 = paramS.D50.val;
    gamma50 = paramS.gamma50.val;
end
%mean dose for selected struct/dose
meanDose = calc_meanDose(doseBinsV, volHistV);

%Compute NTCP
prob = 1./(1+exp(4*gamma50*(1-meanDose/D50)));


%%--- Functions to extract model parameters and weights ----
    function [coeff,par] = getParCoeff(paramS,fieldName,doseBinsV,volHistV)
        
        %Extract relevant parameters
        genFieldC = fields(paramS);
        for i = 1:numel(genFieldC)
            if strcmpi(genFieldC{i},'structures')
                if isstruct(paramS.(genFieldC{i}))
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
        par = zeros(1,length(keepParC));
        coeff = zeros(1,length(keepParC));
        for n = 1:length(keepParC)
            coeff(n) = keepParS.(keepParC{n}).(fieldName);
            if isnumeric(keepParS.(keepParC{n}).val)
                par(n) = keepParS.(keepParC{n}).val;
            else
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