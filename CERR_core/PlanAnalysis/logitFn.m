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
    %Apply Appelt modification to D50, gamma50 for at-risk group
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
    function [coeff,par] = getParCoeff(paramS,parName)
        %Get categories
        fieldC = fields(paramS);
        inpar = 0;
        for i = 1:numel(fieldC)
            if isfield(paramS.(fieldC{i}),'cteg')
            inpar = inpar+1;
            inParC{inpar} = fieldC{i};
            else
                if isfield(paramS.(fieldC{i}),'weight')
                inpar = inpar+1;
                inParC{inpar} = fieldC{i};
                end
            end
        end
        par = zeros(1,numel(inParC));
        coeff = zeros(1,numel(inParC));
        for n = 1:numel(inParC)
            coeff(n) = paramS.(inParC{n}).(parName);
            if isnumeric(paramS.(inParC{n}).val)
               par(n) = paramS.(inParC{n}).val;
            else
                if ~isfield(paramS.(inParC{n}),'params')
                    par(n) = eval([paramS.(inParC{n}).val,...
                        '(doseBinsV, volHistV)']);
                else
                    par(n) = eval([paramS.(inParC{n}).val,...
                        '(doseBinsV, volHistV,paramS.(inParC{n}).params)']);
                end
            end
        end
    end


end