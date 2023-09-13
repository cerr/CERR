function [cerrFeatS,pyFeatS] = compareCerrWithPyrad(cerrParamFile,...
    pyradParamFile,strName,imageType,featureClass,planC)
%----------------------------------------------------------------------
% INPUTS
% strName     : Structure name. Leave empty ('') to use structure from param files
% imageType   : Filtered image type. E.g.: 'original','LoG',{'wavelet','HHH'}
% featureClass: Scalar feature class. E.g.: 'firstorder', 'shape','glcm',
%               'gldm','rlm','szm'.
% 
%----------------------------------------------------------------------
% Example
%----------------------------------------------------------------------
% Load sample data
%fpath = fullfile(fileparts(fileparts(getCERRPath)),...
%        'Unit_Testing/data_for_cerr_tests/CERR_plans/head_neck_ex1_20may03.mat.bz2')
%planC = loadPlanC(fpath,tempdir);
%planC = updatePlanFields(planC);
%planC = quality_assure_planC(fpath,planC);

%pyradParamFile = 'M:\Aditi\PyradiomicsComparison\pytest1.yaml';
%cerrParamFile = 'M:\Aditi\PyradiomicsComparison\cerrtest1.json';
%[cerrFeatS,pyFeatS] = compareCerrWithPyrad(cerrParamFile,...
%                      pyradParamFile,'','original','firstorder',planC);
%----------------------------------------------------------------------
%AI 06/19/2020

indexS = planC{end};

%% 1. Compute features using CERR

%Read param file
paramS = getRadiomicsParamTemplate(cerrParamFile);

%Get structure name
if isempty(strName)
    strName = paramS.structuresC;
    strName = strName{1};
end

strC = {planC{indexS.structures}.structureName};
structNum = getMatchingIndex(strName,strC,'exact');
scanNum = getStructureAssociatedScan(structNum,planC);
structFieldName = ['struct_',repSpaceHyp(strName)];

%Compute features
cerrCalcS.(structFieldName) = calcGlobalRadiomicsFeatures...
    (scanNum, structNum, paramS, planC);

if strcmpi(featureClass,'shape')
    cerrFeatS = cerrCalcS.(structFieldName).shapeS;
else
    cerrFieldsC = fieldnames(cerrCalcS.(structFieldName));
    if iscell(imageType)
        imgClassIdx = true(length(cerrFieldsC),1);
        for n = 1:length(imageType)
            imgClassIdx = imgClassIdx & contains(lower(cerrFieldsC),lower(imageType{n}));
        end
    else
        imgClassIdx = contains(lower(cerrFieldsC),lower(imageType));
    end
    imgClassS = cerrCalcS.(structFieldName).(cerrFieldsC{imgClassIdx});
    featClassC = fieldnames(imgClassS);
    featClassIdx = contains(lower(featClassC),lower(featureClass));
    cerrFeatS = imgClassS.(featClassC{featClassIdx});
end

%% 2. Compute features using Pyradiomics

pyCalcS = calcRadiomicsFeatUsingPyradiomics(planC,strName,pyradParamFile);

if strcmpi(featureClass,'shape')
    retFieldsC = {'shape'};
else
    if iscell(imageType)
        retFieldsC = [lower(imageType),{lower(featureClass)}];
    else
        retFieldsC = {lower(imageType),lower(featureClass)};
    end
end
%Get indices of relevant fields
pyFieldsC = fieldnames(pyCalcS);
returnIdxV = true(length(pyFieldsC),1);
for n = 1:length(retFieldsC)
    returnIdxV = returnIdxV & contains(lower(pyFieldsC),retFieldsC{n});
end

outFieldsC = pyFieldsC(returnIdxV);
pyFeatS = struct();
for n = 1:length(outFieldsC)
    pyFeatS.(outFieldsC{n}) = pyCalcS.(outFieldsC{n});
end


end