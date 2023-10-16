function paramS = addClinicalFactors(paramS,MRNin,CFTable)
% AI 12/8/17

%Get clinical factors
parameterC = fieldnames(paramS);
for k = 1:numel(parameterC)
if isfield(paramS.(parameterC{k}),'val') ...
        && strcmp(paramS.(parameterC{k}).val,'getClinicalFactor')
    factorName = parameterC{k};
    factorVal = getClinicalFactor(MRNin,factorName,CFTable);
    paramS.(parameterC{k}).val = factorVal;
end

end