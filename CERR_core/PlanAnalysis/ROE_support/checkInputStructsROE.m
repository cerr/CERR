function optFlagC = checkInputStructsROE(modelC)
% Identify optional input structures 

optFlagC = cell(1,length(modelC));
for modelNum = 1:length(modelC)
    if isstruct(modelC{modelNum}.parameters.structures)
        structC = fieldnames(modelC{modelNum}.parameters.structures);
        flagV = false(1,length(structC));
        for strNum = 1:length(structC)
            strParS = modelC{modelNum}.parameters.structures.(structC{strNum});
            if isfield(strParS,'optional') && strcmpi(strParS.optional,'yes')
                flagV(strNum) = true;
            end
        end
        optFlagC{modelNum} = flagV;
    else
        optFlagC{modelNum} = false;
    end
end


end