function [featureM,allFieldC] = featureStructToMat(featureS)
% function [featureM,allFieldC] = featureStructToMat(featureS)
% 
% Extracts features values from structure array containing feature to a 2D
% matrix.
%
% APA, 7/1/2018

fieldC = fieldnames(featureS);
for patNum = 1:length(featureS)
    numFeats = 0;
    allFieldC = [];
    for iField = 1:length(fieldC)
        featFieldC = fieldnames(featureS(1).(fieldC{iField}));
        if strcmpi(featFieldC{1},'AvgS')
            featV = full(struct2array(featureS(patNum).(fieldC{iField}).AvgS));
            allFieldC = [allFieldC;...
                strcat(fieldC{iField},'_',fieldnames(featureS(patNum).(fieldC{iField}).AvgS))];
        elseif strcmpi(featFieldC{1},'peak')
            featureS(patNum).(fieldC{iField}) = rmfield(featureS(patNum).(fieldC{iField}),'radius');
            featureS(patNum).(fieldC{iField}) = rmfield(featureS(patNum).(fieldC{iField}),'radiusUnit');
            featV = full(struct2array(featureS(patNum).(fieldC{iField})));
            allFieldC = [allFieldC;...
                strcat(fieldC{iField},'_',fieldnames(featureS(patNum).(fieldC{iField})))];
        else
            featV = full(struct2array(featureS(patNum).(fieldC{iField})));
            allFieldC = [allFieldC;...
                strcat(fieldC{iField},'_',fieldnames(featureS(patNum).(fieldC{iField})))];
        end
        numNewFts = numFeats + length(featV);
        %disp([numFeats numNewFts])
        featureM(patNum,numFeats+1:numNewFts) = featV;
        numFeats = numNewFts;
    end
end
