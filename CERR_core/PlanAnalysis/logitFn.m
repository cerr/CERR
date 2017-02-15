function ntcp = logitFn(paramS,doseBinsV,volHistV)
%
% function ntcp = logitFn(paramS,doseBinsV,volHistV)
%
% This function returns the outcomes probabilities based on logistic fit.
%
% INPUT parameters:
% paramS.modelType: The type of logistic fit, 'D50_GAMMA50' or
% 'MULTIVARIATE'
%
% For D50_GAMMA50 type of fit, 
% Specify the dose calculation function via paramS.doseCalcFunction
% For example: paramS.doseCalcFunction = 'calc_meanDose';
% If paramS.appeltMod = 'yes'; modification for
% risk factors are computed based on Appelt et al.
% if paramS.isHighRiskPatient = 'yes', the patient falls in the high risk
% category.
%
% For MULTIVARIATE type of fit,
% specify the variates using the following format:
% paramS.field1.x = 1;
% paramS.field1.weight = 2;
% 
% paramS.field1.x can also be a string, in which case it will act as a
% function name. This function must have the signature x(doseBinsV,
% volHistV).
% 
% APA, 02/15/2017

modelType = paramS.modelType;

switch upper(modelType)
    
    case 'D50_GAMMA50'
        
        %Get parameters
        D50 = paramS.D50;
        gamma50 = paramS.gamma50;
        doseCalcFunction = paramS.doseCalcFunction;
        additionalInput = [];
        if isfield(paramS,'additionalInput')
            additionalInput = paramS.additionalInput;
        end
        
        % Apply Appelt modification to D50, gamma50 for the risky group
        if isfield(paramS,'appeltMod') && strcmpi(paramS.appeltMod,'yes')
            s = paramS.s;
            OR = paramS.OR;
            [D50, gamma50] = appeltMod(s,OR,D50,gamma50);
            if isfield(paramS,'isHighRiskPatient') && strcmpi(paramS.isHighRiskPatient,'yes')
                D50 = D50 * (1 - 1/4/gamma50*log(OR));
                gamma50 = gamma50  - 1/4*log(OR);
            end
        end
        
        %dose for selected struct/dose
        %dose = calc_meanDose(doseBinsV, volHistV);
        dose = eval([doseCalcFunction,'(doseBinsV, volHistV)',additionalInput]);
        
        %Compute NTCP
        ntcp = 1./(1+exp(4*gamma50*(1-dose/D50)));        
        
    case 'MULTIVARIATE'
        
        fieldNamC = fieldnames(paramS);
        
        % Build the exponent term
        gx = 0;
        for iField = 1:length(fieldNamC)
            weight = paramS.(fieldNamC{iField}).weight;
            x = paramS.(fieldNamC{iField}).x;
            additionalInput = [];
            if isfield(paramS.(fieldNamC{iField}),'additionalInput')
                additionalInput = paramS.(fieldNamC{iField}).additionalInput;
            end
            if ~isnumeric(x)
                % call the function x
                x = eval([x,'(doseBinsV, volHistV)',additionalInput]);
            end
            gx = gx + weight * x;
        end
        
        % Compute NTCP
        ntcp = 1 / (1 + exp(-gx));
end


end