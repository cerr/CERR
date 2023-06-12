function [dataM,featNamC] = fetureStructToMatrix(featuresS)
% fetureStructToMatrix.m 
% 
% Converts feature structure data type to tabular format.
% FeatNameC is the feature name corresponding to each column of dataM.
%
% -------------------------------------------------------------------------
% INPUTS
% featuresS   : Dictionary of features for a selected structure output
%               by calcGlobalRadiomicsFeatures.m. For example, data
%               structure with following fields:               
%             featuresS = 
%               struct with fields:
%
%                   shapeS: [1×1 struct]
%                 Original: [1×1 struct]
% OUTPUT
% featNamC    : Cell array of patient IDs.
% dataM       : matrix of feature values. rows are observations and columns
%               are features.
% -------------------------------------------------------------------------
% APA 6/11/23

% Initialize list of features & feature values
featNamC = {};
dataM = [];

%Get feature classes
featFieldsC = fieldnames(featuresS);
numPts = length(featuresS);

%Record shape features (common across image types)
if any(ismember(featFieldsC,'shapeS'))
    featClassS = [featuresS(:).shapeS];
    fieldNamC = fieldnames(featClassS);
    numFeat = length(fieldNamC);
    featM = nan(numPts,numFeat);
    for iField = 1:numFeat
        featM(:,iField) = [featClassS.(fieldNamC{iField})]';
    end
    featNamC=[featNamC;strcat('Shape_',fieldNamC)];
    dataM=[dataM featM];
end

%Loop over image types
imageTypeC = featFieldsC(~ismember(featFieldsC,{'shapeS','fileName'}));
for type = 1:length(imageTypeC)
    imgType = imageTypeC{type};
    imgFeatS = [featuresS(:).(imgType)];
    featClassesC = fieldnames(imgFeatS);
    
    %Loop over feature classes
    for nClass = 1:length(featClassesC)
        featClass = featClassesC{nClass};
        
        switch(featClass)
            case {'ngtdmFeatS','ngldmFeatS','szmFeatS','firstOrderS',...
                    'peakValleyFeatureS','ivhFeaturesS'}
                
                featClassS = [imgFeatS.(featClass)];
                fieldNamC = fieldnames(featClassS);
                numFeat = length(fieldNamC);
                featM = nan(numPts,numFeat);
                for iField = 1:numFeat
                    featVal1 = featClassS.(fieldNamC{iField});
                    if ~ischar(featVal1) && size(featVal1,2)==1
                        featVal = [featClassS.(fieldNamC{iField})]';
                        %if length(featVal)>1
                        %    %featVal = num2str(featVal);
                        %    featVal = strjoin(""+featVal,", ");
                        %end
                        if size(featVal,2)==1
                            featM(:,iField) = featVal;
                        end
                    end
                end
                featNamC = [featNamC;strcat([imgType,'_',featClass,'_'],fieldNamC)];
                dataM = [dataM featM];
                
            case {'harFeatS','glcmFeatS','rlmFeatS'}
                featClassS = [imgFeatS(:).(featClass)];
                subFieldsC = {'AvgS','MaxS','MinS','StdS','MadS'};
                for nSub = 1:length(subFieldsC)
                    combFeatS = [featClassS.(subFieldsC{nSub})];
                    fieldNamC = fieldnames(combFeatS);
                    fieldSubSieldC = strcat(...
                        [imgType,'_',featClass,'_',subFieldsC{nSub},'_'],fieldNamC);
                    numFeat = length(fieldNamC);
                    featM = nan(numPts,numFeat);
                    for iField = 1:numFeat
                        featVal1 = combFeatS(1).(fieldNamC{iField});
                        if ~ischar(featVal1) && size(featVal1,2)==1
                            featVal = [combFeatS.(fieldNamC{iField})]';
                            if size(featVal,2)==1
                                featM(:,iField) = featVal;
                            end
                        end
                    end
                    featNamC = [featNamC;fieldSubSieldC];
                    dataM=[dataM, featM];
                end
                
            case {'harFeatcombS','rlmFeatcombS'}
                featClassS = [imgFeatS.(featClass)];
                combFeatS = [featClassS.CombS];
                fieldNamC = fieldnames(combFeatS);
                numFeat = length(fieldNamC);
                featM = nan(numPts,numFeat);
                for iField = 1:length(fieldNamC)
                    featVal1 = combFeatS(1).(fieldNamC{iField});
                    if ~ischar(featVal1) && size(featVal1,2)==1
                        featVal = [combFeatS.(fieldNamC{iField})]';
                        if size(featVal,2)==1
                            featM(:,iField) = featVal;
                        end
                    end
                end
                featNamC = [featNamC;strcat([imgType,'_',featClass,'_'],fieldNamC)];
                dataM=[dataM featM];
                
        end
    end
   
    
end
