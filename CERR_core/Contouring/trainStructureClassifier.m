function SVMmodelS = trainStructureClassifier(dirName,structName,haralOnlyFlag,flagV,numGrLevel,patchRadius)
% -------------- INPUTS ----------------------
% dirName      : Path to directory containing CERR plans
% structName   : Name of structure of interest (as appears in CERR file)
% --- For texture features ---
% haralOnlyFlag: Set to 0 to compute Haralicka and Laws textures, 1 for Haralick only
% flagV        : Vector of flags indicating haralick textures to be computed
%               flagV = [energyFlg,entropyFlag,sumAvgFlg,homogFlg,...
%               contrastFlg,corrFlg,clustShadFlg,clustPromFlg,haralCorrFlg];
% numGrLevel  : No. gray levels for texture calc  
% patchRadius : Patch radius for texture calc  
% ---------------------------------------------
% Usage eg.:
% SVMmodel = trainStructureClassifier('H:\Public\Aditya\mimExtensions\Atlas_Sanne\CT_cerr\Training',...
%                                    'Parotid_L_SvD',1,[1,1,1,1,1,1,0,0,0],64,2);
% ---------------------------------------------
% APA, 8/31/2017
% AI, 9/1/17

% Get plans in training directory
dirS = dir(dirName);
dirS(1:2) = [];

% Cropping/Clipping parameters
rowMargin = 25; % extend rows by this amount around structure
colMargin = 25; % extend cols by this amount
slcMargin = 5; % extend slcs by this amount
minIntensity = -200;   % Clipping min
maxIntensity = 400; % Clipping max

% Loop over all planC files
combinedFeaturesM = [];
combinedSiz = 0;
labelsV = [];
nanIntensityV = [];
rng(1);
for planNum = 1:length(dirS)
    
    fileNam = fullfile(dirName,dirS(planNum).name);
    
    planC = loadPlanC(fileNam, tempdir);
    
    planC = quality_assure_planC(fileNam,planC);
    indexS = planC{end};
    
    % Find matching structure
    structNum = getMatchingIndex(lower(structName),lower(...
        {planC{indexS.structures}.structureName}),'exact');
    
    % Identify associated scan
    scanNum = getStructureAssociatedScan(structNum, planC);
    
    % Get Haralick textures 
    [featuresM,volToEval,mask3M,minr,maxr,minc,maxc,mins,maxs] = getLawsAndHaralickFeatures(structNum,...
        rowMargin,colMargin,slcMargin,minIntensity,maxIntensity,planC,haralOnlyFlag,flagV,numGrLevel,patchRadius);
    nanCurrentV = reshape(isnan(volToEval),[],1);
    nanIntensityV = [nanIntensityV;nanCurrentV];
    
    % Get location (distance from isocenter)    %Added
    bbox3M = false(size(getScanArray(scanNum,planC)));  
    bbox3M(minr:maxr,minc:maxc,mins:maxs)= true;
    [cX,cY,cZ] = calcIsocenter(structNum, 'COM', planC);
    [xV,yV,zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
    [xM,yM,zM] = meshgrid(xV,yV,zV);
    distV = bsxfun(@minus,[xM(bbox3M),yM(bbox3M),zM(bbox3M)], [cX,cY,cZ]);
    
    % Assemble the feature matrix numVoxels x numFeatures
    combinedFeaturesM = [combinedFeaturesM;featuresM,distV(~nanCurrentV,:)];
    
    % Get labels
    siz = numel(mask3M);
    labelsV = [labelsV;reshape(mask3M,siz,1)];
    combinedSiz = combinedSiz + siz;
end
trainFeaturesM = zeros(combinedSiz,size(combinedFeaturesM,2));
trainFeaturesM(~nanIntensityV,:) = combinedFeaturesM;


%Generate  SVM model
% Note: Swap with Python's Scikit in future
CERRStatusString('Training classifier...','console');
SVMmodelS = fitcsvm(trainFeaturesM,labelsV,'KernelFunction','RBF','KernelScale','auto',...
    'Standardize',true,'BoxConstraint',10,'IterationLimit',2000,'verbose',2);
CERRStatusString('Complete.','console');

end


