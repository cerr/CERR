function prob = logitFn(paramS,doseBinsV,volHistV)
%
% function prob = logitFn(paramS,doseBinsV,volHistV)
%
% This function returns the outcomes probabilities based on logistic fit.
%
% INPUT parameters:
% paramS.modelSubtype: The type of logistic fit, 'D50_GAMMA50' or
% 'MULTIVARIATE'
%
% For D50_GAMMA50 type of fit,
% If paramS.appeltMod = 'yes'; modification for
% risk factors are computed based on Appelt et al.
% if paramS.isHighRiskPatient = 1, the patient falls in the high risk
% category.
%
% For MULTIVARIATE type of fit,
% specify the variates using the following format:
% paramS.field1.val = 1;
% paramS.field1.weight = 2;
%
% paramS.field1.val can also be a string, in which case it will act as a
% function name. This function must have the signature x(doseBinsV,
% volHistV).
%
% APA, 02/15/2017
% AI, 02/21/17

modelType = paramS.modelSubtype.val;

switch upper(modelType)
    
    case 'D50_GAMMA50'
        %Apply Appelt modification to D50, gamma50 for the risky group
        if isfield(paramS,'appeltMod') && strcmpi(paramS.appeltMod.val,'yes')
            % Get OR
            [or,weight] = getParCoeff(paramS,'OR');
            orMult = or(weight==1);
            OR = prod(orMult);
            %Get modified D50, gamma50
            [D50, gamma50] = appeltMod(OR);
        else
            D50 = paramS.D50.val;
            gamma50 = paramS.gamma50.val;
        end
        %mean dose for selected struct/dose
        meanDose = calc_meanDose(doseBinsV, volHistV);
        
        %Compute NTCP
        prob = 1./(1+exp(4*gamma50*(1-meanDose/D50)));
        
    case 'MULTIVARIATE'
        [x,weight] = getParCoeff(paramS,'weight');
        gx = sum(weight.*x);
        % Compute TCP/NTCP
        prob = 1 / (1 + exp(-gx));
end

%%
    function [par,coeff] = getParCoeff(paramS,parName)
        %Get categories
        fieldC = fields(paramS);
        ctg = 0;
        for i = 1:numel(fieldC)
            if isfield(paramS.(fieldC{i}),'cteg')
            ctg = ctg+1;
            ctegC{ctg} = fieldC{i};
            end
        end
        coeff = zeros(1,numel(ctegC));
        par = zeros(1,numel(ctegC));
        for n = 1:numel(ctegC)
            par(n) = paramS.(ctegC{n}).(parName);
            if isnumeric(paramS.(ctegC{n}).val)
               coeff(n) = paramS.(ctegC{n}).val;
            else
                if ~isfield(paramS.(ctegC{n}),'params')
                    coeff(n) = eval([paramS.(ctegC{n}).val,...
                        '(doseBinsV, volHistV)']);
                else
                    coeff(n) = eval([paramS.(ctegC{n}).val,...
                        '(doseBinsV, volHistV,paramS.(ctegC{n}).params)']);
                end
            end
        end
    end


end