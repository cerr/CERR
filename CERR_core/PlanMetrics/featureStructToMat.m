function [featureM,allFieldC] = featureStructToMat(featureS)
% function [featureM,allFieldC] = featureStructToMat(featureS)
%
% Extracts features values from structure array containing feature to a 2D
% matrix.
%
% INPUT:
%   featureS structure array (output from batchExtractRadiomics.m)
%   containing radiomics features for the structures of interest.
%       featureS = 
%           1×100 struct array with fields:
%               struct_roi1
%               struct_roi2
%               fileName
%
% OUTPUT:
%  featureM: nxm matrix containing m radiomics features for n samples.
%  allFieldC: names of m radiomics features.
%
% APA, 7/1/2018

imgC = fieldnames(featureS);
for patNum = 1:length(featureS) % patients loop
    numFeats = 0;
    allFieldC = [];
    for iImg = 1:length(imgC) % imageType loop
        imgType = imgC{iImg};
        if ~isstruct(featureS(1).(imgType))
            continue;
        end
        featureForImgTypeS = [featureS.(imgType)];
        fieldC = fieldnames(featureForImgTypeS);
        for iField = 1:length(fieldC) % radiomics features loop
            if isstruct(featureForImgTypeS(1).(fieldC{iField}))
                featFieldC = fieldnames(featureForImgTypeS(1).(fieldC{iField}));                
                if strcmpi(featFieldC{1},'AvgS')
                    featV = full(struct2array(featureForImgTypeS(patNum).(fieldC{iField}).AvgS));
                    allFieldC = [allFieldC;...
                        strcat(imgType,'_',fieldC{iField},'_',...
                        fieldnames(featureForImgTypeS(patNum).(fieldC{iField}).AvgS))];
                elseif strcmpi(featFieldC{1},'peak')
                    featureForImgTypeS(patNum).(fieldC{iField}) = ...
                        rmfield(featureForImgTypeS(patNum).(fieldC{iField}),'radius');
                    featureForImgTypeS(patNum).(fieldC{iField}) = ...
                        rmfield(featureForImgTypeS(patNum).(fieldC{iField}),'radiusUnit');
                    featV = full(struct2array(featureForImgTypeS(patNum).(fieldC{iField})));
                    allFieldC = [allFieldC; strcat(imgType,'_',...
                        fieldC{iField},'_',fieldnames(featureForImgTypeS(patNum).(fieldC{iField})))];
                else
                    featV = full(struct2array(featureForImgTypeS(patNum).(fieldC{iField})));
                    allFieldC = [allFieldC; strcat(imgType,'_',fieldC{iField},...
                        '_',fieldnames(featureForImgTypeS(patNum).(fieldC{iField})))];
                end
                numNewFts = numFeats + length(featV);
                featureM(patNum,numFeats+1:numNewFts) = featV;
                numFeats = numNewFts;
            end
        end
    end
end
