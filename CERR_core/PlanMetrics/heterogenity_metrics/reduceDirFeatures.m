function featureReducedS = reduceDirFeatures(featuresAllDirS, reduceType)
% function featureReducedS = reduceDirFeatures(featuresAllDirS, reduceType)
%
% This function combines the directional feature values into a single
% value. The reduceType specifies how the different directions should be
% combined. The supported reduceTypes are 'avg', 'max', 'min', 'std',
% 'mad', 'iqr'
%
% APA, 4/11/2017

filedNamC = fieldnames(featuresAllDirS);

for iField = 1:length(filedNamC)
    fieldName = filedNamC{iField};
    switch lower(reduceType)
        case 'avg'
            featureReducedS.(fieldName) = mean([featuresAllDirS.(fieldName)]);
        case 'min'
            featureReducedS.(fieldName) = min([featuresAllDirS.(fieldName)]);
        case 'max'
            featureReducedS.(fieldName) = max([featuresAllDirS.(fieldName)]);
        case 'std'
            featureReducedS.(fieldName) = std([featuresAllDirS.(fieldName)]);
        case 'mad'
            featureReducedS.(fieldName) = mad([featuresAllDirS.(fieldName)]);
        case 'iqr'
            featureReducedS.(fieldName) = mad([featuresAllDirS.(fieldName)]);
    end
end


