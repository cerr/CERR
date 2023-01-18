function featureS = batchExtractRadiomics(dirName,paramFileName,strNumV)
% function featureS = batchExtractRadiomics(dirName,paramFileName,strNumV)
% 
% Extract radiomics features for a cohort of CERR files. Features for multiple 
% structures can be extracted simultaneously by specifying their names in
% the .json file under the "structures" field.
%
% INPUT: 
%   dirName - directory containing CERR files.
%   paramFileName - .json file containing parameters for radiomics calculation.
% Optional:
%   strNumV - Vector of structure nos. for each CERR file. If empty/missing,
%   structure no. is identified from name provided in paramFile.
%
% OUTPUT:
%   featureS - data structure for radiomics features. 
%       Features for each structures are stored under featureS.(struct_structureName)
%
% APA, 3/26/2019

if ~exist('strNumV','var')
    strNumV = [];
end

% Read JSON parameter file
paramS = getRadiomicsParamTemplate(paramFileName);

%Get file names
dirS = rdir(dirName);
all_filenames = {dirS.fullpath};

if length(strNumV) == 1
    strNumV = repmat(strNumV,[1,length(all_filenames)]);
end

% Initialize empty features
featureS = [];

% Loop over CERR files in all dirs/sub-dirs
for iFile = 1:length(all_filenames)
    
    %Load file
    fullFname = all_filenames{iFile};
    planC = loadPlanC(fullFname, tempdir);
    planC = updatePlanFields(planC);
    planC = quality_assure_planC(fullFname, planC);
    indexS = planC{end};

    %Get structure no.
    if isempty(strNumV)
        strC = {planC{indexS.structures}.structureName}; %All structures
        for iStr = 1:length(paramS.structuresC)
            structNum = getMatchingIndex(paramS.structuresC{iStr},strC,'exact');
            scanNum = getStructureAssociatedScan(structNum,planC);
            structFieldName = ['struct_',repSpaceHyp(paramS.structuresC{iStr})];
            featS.(structFieldName) = calcGlobalRadiomicsFeatures...
                (scanNum, structNum, paramS, planC);
        end
    else
        structNum = strNumV(iFile);
        scanNum = getStructureAssociatedScan(structNum,planC);
        structFieldName = ['struct_',repSpaceHyp(paramS.structuresC{iStr})];
        featS.(structFieldName) = calcGlobalRadiomicsFeatures...
            (scanNum, structNum, paramS, planC);
    end
    
    featS.fileName = all_filenames{iFile};
    
    if isempty(featureS)
        featureS = featS;
    else
        featureS(iFile) = featS;
    end    
    
end

% Write output to Excel file if outXlsFile exists
% if exist('outXlsFile','var')    
%     structC = fieldnames(featureS);
%     fileNamC = {featureS.fileName};
%     indKeepV = ~strncmpi('fileName',structC,length('filename'));
%     structC = structC(indKeepV);
%     for iStruct = 1:length(structC)
%         combinedFieldNamC = {};
%         combinedFeatureM = [];
%         featureForStructS = [featureS.(structC{iStruct})];
%         imgC = fieldnames(featureForStructS);
%         for iImg = 1:length(imgC)
%              [featureM,allFieldC] = featureStructToMat([featureForStructS.(imgC{iImg})]);
%              combinedFieldNamC = [combinedFieldNamC; strcat(allFieldC,'_',imgC{iImg})];
%              combinedFeatureM = [combinedFeatureM, featureM];
%         end
%         xlswrite(outXlsFile, ['File Name';combinedFieldNamC]', structC{iStruct}, 'A1');
%         xlswrite(outXlsFile, fileNamC(:), structC{iStruct}, 'A2');
%         xlswrite(outXlsFile, combinedFeatureM, structC{iStruct}, 'B2');
%     end
% end

end
   
