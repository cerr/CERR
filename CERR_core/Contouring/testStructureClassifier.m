function testStructureClassifier(dirName,structName,SVMmodelS,haralOnlyFlag,flagV,numGrLevel,patchRadius)
% trainStructureClassifier(dirName,structName,SVMmodelS,haralOnlyFlag,flagV,numGrLevel,patchRadius)
% -------------- INPUTS ----------------------
% dirName      : Path to directory containing CERR plans
% structName   : Name of structure of interest (as appears in CERR file) 
% SVMmodelS    : SVM model 
% haralOnlyFlag: Set to 0 to compute Haralicka and Laws textures, 1 for Haralick only
% flagV        : Vector of flags indicating haralick textures to be computed
%               flagV = [energyFlg,entropyFlag,sumAvgFlg,homogFlg,...
%               contrastFlg,corrFlg,clustShadFlg,clustPromFlg,haralCorrFlg];
% numGrLevel  : No. gray levels for texture calc  
% patchRadius : Patch radius for texture calc     
% ---------------------------------------------
% AI, 9/12/17

% Get plans in test directory
dirS = dir(dirName);
dirS(1:2) = [];

% Cropping/Clipping parameters
rowMargin = 25;          % extend rows by this amount around structure 
colMargin = 25;          % extend cols by this amount
slcMargin = 5;           % extend slcs by this amount
minIntensity = -200;     % Clipping min
maxIntensity = 400;      % Clipping max

% Loop over CERR archives
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
    
    %Indices of excluded voxels
    nanIntensityV = reshape(isnan(volToEval),[],1);
    
    % Get location (distance from isocenter)
    bbox3M = false(size(getScanArray(scanNum,planC))); %Added AI
    bbox3M(minr:maxr,minc:maxc,mins:maxs)= true;
    [cX,cY,cZ] = calcIsocenter(structNum, 'COM', planC);
    [xV,yV,zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
    [xM,yM,zM] = meshgrid(xV,yV,zV);
    distV = bsxfun(@minus,[xM(bbox3M),yM(bbox3M),zM(bbox3M)], [cX,cY,cZ]);

    featuresM = [featuresM,distV(~nanIntensityV,:)];
        
    %Standardize
    testFeaturesM = zeros(numel(mask3M),size(featuresM,2));
    testFeaturesM(~nanIntensityV,:) = featuresM;

    %Get labels
    CERRStatusString('Generating labels...','console');
    labelV = predict(SVMmodelS,testFeaturesM); 
    CERRStatusString('Complete.','console');

    %Reshape to mask
    label3M = zeros(size(bbox3M));
    labOut3M = label3M;
    label3M(bbox3M) = labelV;
    
    %Morphological processing
    for n = 1:size(label3M,3)
        labFillM = imfill(label3M(:,:,n),'holes');
        labMajM = bwmorph(labFillM,'majority');
        labOut3M(:,:,n) = bwareaopen(labMajM,25);
    end

    %Save to planC
    planC = maskToCERRStructure(labOut3M,0,1,'SVM_Out',planC);
    save_planC(planC,[],'saveas',fileNam);
end

end 


