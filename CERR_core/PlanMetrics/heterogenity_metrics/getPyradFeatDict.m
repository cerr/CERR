function pySelFeatS = getPyradFeatDict(pyFeatAllS,fieldListC)
% Extract specified radiomics features from pyrad dictionary
%
% AI 07/01/2020

pyFieldsC = fieldnames(pyFeatAllS);

%Get indices of relevant fields
selFeatClassIdxV = true(length(pyFieldsC),1);
for n = 1:length(fieldListC)
    selFeatClassIdxV = selFeatClassIdxV & contains(pyFieldsC,fieldListC{n});
end

%Create feature dictionary
selFeatFieldsC = pyFieldsC(selFeatClassIdxV);
pySelFeatS = struct();
for n = 1:length(selFeatFieldsC)
    pySelFeatS.(selFeatFieldsC{n}) = pyFeatAllS.(selFeatFieldsC{n});
end



end