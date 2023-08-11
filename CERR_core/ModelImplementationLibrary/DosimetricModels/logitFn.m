function prob = logitFn(paramS,doseBinsC,volHistC)
% function prob = logitFn(paramS,doseBinsC,volHistC);
% This function returns the outcomes probabilities based on logistic fit.
%----------------------------------------------------------------------------
% INPUT parameters:
% paramS:
% Specify the variates using the following format:
% paramS.field1.val = 1;
% paramS.field1.weight = 2;
% paramS.field1.val can also be a string, in which case it will act as a
% function name. This function must have the signature
% x(doseBinsV,volHistV).
%---------------------------------------------------------------------------
% APA, 02/15/2017
% AI, 02/21/17
% AI , 11/14/17  Created separate function for appelt model
% AI, 11/16/17   Copy number of fractions, abRatio to any sub-parameter structures

%Extract parameters and corresponding weights 
[weight,x] = getParCoeff(paramS,'weight',doseBinsC,volHistC);
%Compute TCP/NTCP
gx = sum(weight.*x);
prob = 1 / (1 + exp(-gx));


%%--- Functions to extract model parameters and weights ----
    function [coeff,par] = getParCoeff(paramS,fieldName,doseBinsC,volHistC)
        
        %Extract relevant parameters
        genFieldC = fieldnames(paramS);
        for i = 1:numel(genFieldC)
            if strcmpi(genFieldC{i},'structures')
                structS = paramS.(genFieldC{i});
                structListC = fieldnames(structS);
                for j = 1:length(structListC)
                    strParamS = structS.(structListC{j});
                    strParamListC = fieldnames(strParamS);
                    for k = 1 : numel(strParamListC)
                        if isfield(strParamS.(strParamListC{k}),'cteg') ||  isfield(strParamS.(strParamListC{k}),'weight')
                            parName = [structListC{j},strParamListC{k}];
                            keepParS.(parName) = strParamS.(strParamListC{k});
                        end
                    end
                end
            else
                 if isfield(paramS.(genFieldC{i}),'cteg') ||  isfield(paramS.(genFieldC{i}),'weight')
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
                    if isfield(paramS,'numFractions')
                        keepParS.(keepParC{n}).params.numFractions.val = paramS.numFractions.val;
                    end
                    if isfield(paramS,'abRatio')
                        keepParS.(keepParC{n}).params.abRatio.val = paramS.abRatio.val;
                    end
                    par(n) = eval([keepParS.(keepParC{n}).val,...
                        '(doseBinsV, volHistV,keepParS.(keepParC{n}).params)']);
                end
            end
        end
    end


end