function featureS = batchExtractRadiomics(dirName,paramFileName,strFileMapC)
% function featureS = batchExtractRadiomics(dirName,paramFileName,strFileMapC)
% 
% Extract radiomics features for a cohort of CERR files. Features for multiple 
% structures can be extracted simultaneously by specifying their names in
% the .json file under the "structures" field.
%
% INPUT: 
%   dirName - directory containing CERR files.
%   paramFileName - .json file containing parameters for radiomics calculation.
% Optional:
%   strFileMapC - CellArray of size Nx2 containing 1st element as filename
%         and 2nd element as structure index. If empty/missing, structure no.
%         is identified from planC using the structure name provided in paramFileName.
%
% OUTPUT:
%   featureS - data structure for radiomics features. 
%       Features for each structures are stored under featureS.(struct_structureName)
%
% APA, 3/26/2019

if ~exist('strFileMapC','var')
    strNumV = [];
end

% Read JSON parameter file
paramS = getRadiomicsParamTemplate(paramFileName);

%Get file names
dirS = rdir(dirName);
all_filenames = {dirS.fullpath};

% Get structNumV for the passed strFileMapC
if exist('strFileMapC','var') && iscell(strFileMapC)
    fileNamC = {dirS.name};
    fileIdC = strFileMapC(:,1);
    structIndV = [strFileMapC{:,2}];
    strNumV = nan(length(fileNamC),1);
    for idNum = 1:length(fileIdC)
        fileId = fileIdC{idNum};
        idMatch = find(strncmp(fileId,fileNamC,length(fileId)));
        if any(idMatch)
            strNumV(idMatch) = structIndV(idNum);
        end
    end
else
    strNumV = [];
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

    writeFeatFlag = false;
    %Get structure no.
    if isempty(strNumV)
        strC = {planC{indexS.structures}.structureName}; %All structures
        for iStr = 1:length(paramS.structuresC)
            structNum = getMatchingIndex(paramS.structuresC{iStr},strC,'exact');
            if isempty(structNum) || isnan(structNum)
                continue;
            end
            scanNum = getStructureAssociatedScan(structNum,planC);
            structFieldName = ['struct_',repSpaceHyp(paramS.structuresC{iStr})];
            featS.(structFieldName) = calcGlobalRadiomicsFeatures...
                (scanNum, structNum, paramS, planC);  
            writeFeatFlag = true;
        end
    else
        structNum = strNumV(iFile);
        if isempty(structNum) || isnan(structNum)
            continue;
        end
        scanNum = getStructureAssociatedScan(structNum,planC);
        structName = planC{indexS.structures}(structNum).structureName;
        %structFieldName = ['struct_',repSpaceHyp(structName)];
        featS = calcGlobalRadiomicsFeatures...
            (scanNum, structNum, paramS, planC);
        writeFeatFlag = true;
    end
    
    if writeFeatFlag
        featS.fileName = all_filenames{iFile};
        
        if isempty(featureS)
            featureS = featS;
        else
            featureS(end+1) = featS;
        end
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
   
