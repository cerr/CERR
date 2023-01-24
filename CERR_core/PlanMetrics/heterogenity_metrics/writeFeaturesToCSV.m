function writeFeaturesToCSV(featuresS,csvFile,idC)
% writeFeaturesToCSV.m Writes scalar radiomic texture features ("featuresS")
% computed for a cohort using calcGlobalRadiomicsFeatures.m to a CSV file.
% -------------------------------------------------------------------------
% INPUTS
% featuresS   : Dictionary of features output by calcGlobalRadiomicsFeatures.m
% csvFile     : Path to output CSV file.
% idC         : Cell array of patient IDs. 
% -------------------------------------------------------------------------
% AI 1/16/23

%Get patient IDs
numPts = length(featuresS);
if ~exist('idC','var')
    ptC = num2cell(1:numPts);
    idC = cellfun(@num2str,ptC,'un',0);
    idC = strcat('Pt ',idC);
end

% Initialize list of features & feature values
variableC = {};
dataM = [];

%Get feature classes
fieldsC = fieldnames(featuresS);
%strFeaturesS = [featuresS(:).(fieldsC{1})];
%featFieldsC = fieldnames(strFeaturesS);
featFieldsC = fieldnames(featuresS);

%Record shape features (common across image types)
if any(ismember(featFieldsC,'shapeS'))
    featClassS = [featuresS(:).shapeS];
    %featClassS = [strFeaturesS(:).shapeS];
    fieldNamC = fieldnames(featClassS);
    numFeat = length(fieldNamC);
    featM = nan(numPts,numFeat);
    for iField = 1:numFeat
        featM(:,iField) = [featClassS.(fieldNamC{iField})]';
    end
    variableC=[variableC;strcat('Shape_',fieldNamC)];
    dataM=[dataM featM];
end

%Loop over image types
imageTypeC = featFieldsC(~ismember(featFieldsC,{'shapeS','fileName'}));
for type = 1:length(imageTypeC)
    %imgFeatS = [strFeaturesS(:).(imageTypeC{type})];
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
                variableC = [variableC;strcat([imgType,'_',featClass,'_'],fieldNamC)];
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
                    variableC = [variableC;fieldSubSieldC];
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
                variableC = [variableC;strcat([imgType,'_',featClass,'_'],fieldNamC)];
                dataM=[dataM featM];

%             case 'ivhFeaturesS'
%                 featClassS = [imgFeatS(:).(featClass)];
%                 featListC = fieldnames(featClassS);
% 
%                 %All supported feature categories
%                 allCtegC = {'Ix','IabsX','Vx','VabsX','MOHx','MOCx'}; 
% 
%                 ivhFeatM = [];
%                 availCtegC = {};
%                 for cNum = 1:length(allCtegC)
%                     matchIdxV = find(contains(featListC,allCtegC{cNum}));
%                     if ~isempty(matchIdxV)
%                         % variable name
%                         matchVar = {};
%                         matchVal = [];
%                         for i = 1:length(matchIdxV)
%                             matchVar = [matchVar,featListC{matchIdxV(i)}];
%                             allVal = [featClassS.(featListC{matchIdxV(i)})]';
%                             matchVal = [matchVal, allVal];
%                         end
%                     end
%                     availCtegC = [availCtegC,matchVar];
%                     ivhFeatM = [ivhFeatM,matchVal];
%                 end
% 
%                 variableC=[variableC;availCtegC'];
%                 dataM=[dataM ivhFeatM];
        end
    end

    %CSV file headings
    outC = cell(numPts,1);
    rowHeadings = strjoin(variableC,',');
    rowHeadings = ['id,',rowHeadings];
    outC{1} = rowHeadings;

    %Write to file
    for pt = 1:size(dataM,1)
        lineStr = [idC{pt},',',sprintf('%.5g,' ,dataM(pt,:))];
        lineStr(end) = [];
        outC{pt+1} = lineStr;
    end
    cell2file(outC,csvFile);

end