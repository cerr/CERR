function featureS = batchExtractRadiomics(dirName,paramFileName)
% function featureS = batchExtractRadiomics(dirName,paramFileName)
% 
% Extract radiomics features for a cohort of CERR files. Features for multiple 
% structures can be extracted simultaneously by specifying their names in
% the .json file under the "structures" field.
%
% INPUT: 
%   dirName - directory containing CERR files.
%   paramFileName - .json file containing parameters for radiomics calculation.
%
% OUTPUT:
%   featureS - data structure for radiomics features. 
%       Features for each structures are stored under featureS.(struct_structureName)
%
% APA, 3/26/2019

% Read JSON parameter file
paramS = getRadiomicsParamTemplate(paramFileName);

% Loop over CERR files in all dirs/sub-dirs
dirS = rdir(dirName);
all_filenames = {dirS.fullpath};

% Initialize empty features
featureS = [];

for iFile = 1:length(all_filenames)
    
    fullFname = all_filenames{iFile};
    
    planC = loadPlanC(fullFname, tempdir);
    
    planC = quality_assure_planC(fullFname, planC);
    
    indexS = planC{end};
    
    strC = {planC{indexS.structures}.structureName};
    
    for iStr = 1:length(paramS.structuresC)
        structNum = getMatchingIndex(paramS.structuresC{iStr},strC,'exact');
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

