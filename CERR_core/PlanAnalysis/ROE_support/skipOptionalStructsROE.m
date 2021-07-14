function modelC = skipOptionalStructsROE(modelC,optFlagC,strSelC)
%Exclude optional structures with no user input

optStrC = cellfun(@any,optFlagC,'un',0);
optIdxV = [optStrC{:}];
if any(optIdxV)
optModC = modelC(optIdxV);
strSelV = strSelC{optIdxV};
flagV = optFlagC{optIdxV} & strSelV==0;
skipIdxV = find(flagV);
else
    optModC = {};
end

for m = 1:length(optModC)
    
    modS = optModC{m};
    strS = modS.parameters.structures;
    strC = fieldnames(strS);
    for n = 1:length(skipIdxV)
        strS = rmfield(strS,strC{skipIdxV(n)});
    end
    modS.parameters.structures = strS;
    optModC{m} = modS;
    optModC{m}.strNum(skipIdxV(n))=[];
end

modelC(optIdxV) = optModC;


end