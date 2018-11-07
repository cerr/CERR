function planC = createPCimage(scanNum,structNumV,pcaParamsFile,planC)
% function createPCimage(scanNum,structNumV,pcaParamsFile,planC)
%
% APA, 2/4/2017

if ~iscell(scanNum)
    
    rowMargin = 100; % extend rows by this amount
    colMargin = 512; % extend cols by this amount
    slcMargin = 7; % extend slcss by this amount  %Changed from 15
    
    if ~exist('planC','var')
        global planC
    end
    
    indexS = planC{end};
    
    % get ROI
    randomFlg = 1;
    [volToEval,maskBoundingBox3M,mask3M,minr,maxr,minc,maxc,mins,maxs,uniqueSlices] = ...
        getROI(structNumV,rowMargin,colMargin,slcMargin,planC,randomFlg);
    
    sliceThickNessV = ...
        [planC{indexS.scan}(scanNum).scanInfo(mins:maxs).sliceThickness];
    [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
    
else
    
    volToEval = scanNum{1};
    maskBoundingBox3M = scanNum{2};
    mask3M = scanNum{3};
    minr = scanNum{4};
    maxr = scanNum{5};
    minc = scanNum{6};
    maxc = scanNum{7};
    mins = scanNum{8};
    maxs = scanNum{9};
    uniqueSlices = scanNum{10};
    sliceThickNessV = scanNum{11};
    xVals = scanNum{12};
    yVals = scanNum{13};
    zVals = scanNum{14};
    rowMargin = [];
    colMargin = [];
    slcMargin = [];
end

minIntensity = -200;   % Clipping min
maxIntensity = 400; % Clipping max
harOnlyFlg = 1;
featFlagsV = [1,1,1,1,1,1,1,1,1];
numLevsV = 64;
patchRadiusV = [1,2];
compNumV = 1:2;

load(pcaParamsFile)

% Clip intensities
% volToEval(volToEval < minIntensity) = minIntensity;
% volToEval(volToEval > maxIntensity) = maxIntensity;
nanIntenityV = volToEval < -400;

%%% AA commented for writing cropped CT scans

% Get Law's and Haralick features for this structure
newFeaturesM = getLawsAndHaralickFeatures({volToEval,maskBoundingBox3M},...
    rowMargin,colMargin,slcMargin,minIntensity,maxIntensity,planC);
% rowMargin = [];
% colMargin = [];
% slcMargin = [];
% newFeaturesM = gpuGetLawsAndHaralickFeatures({volToEval,maskBoundingBox3M},...
%         rowMargin,colMargin,slcMargin,minIntensity,maxIntensity,planC,...
%         harOnlyFlg,featFlagsV,numLevsV,patchRadiusV);
newFeaturesM = bsxfun(@minus,newFeaturesM, featureMeanV);
newFeaturesM = bsxfun(@rdivide,newFeaturesM, featureStdV);
%newFeaturesM = newFeaturesM(:,indSignifV);


siz = size(maskBoundingBox3M);

% Parameters for storing component image to planC
deltaXYZv = [abs(xVals(1)-xVals(2)) abs(yVals(1)-yVals(2)) abs(zVals(1)-zVals(2))];
zV = zVals(mins:maxs);
regParamsS.horizontalGridInterval = deltaXYZv(1);
regParamsS.verticalGridInterval   = deltaXYZv(2); %(-)ve for dose
regParamsS.coord1OFFirstPoint   = xVals(minc);
%regParamsS.coord2OFFirstPoint   = yVals(minr); % for dose
regParamsS.coord2OFFirstPoint   = yVals(maxr);
regParamsS.zValues  = zV;
regParamsS.sliceThickness = sliceThickNessV;
assocTextureUID = '';
for compNum = compNumV
    
    %% Plot components, raw image and segmentation
    compV = zeros(prod(siz),1);
    
    compV(~nanIntenityV) = newFeaturesM * coeff(:,compNum) * 1.0 + newFeaturesM * coeff(:,2) * 0.0 + ...
        newFeaturesM * coeff(:,3) * 0.0 + newFeaturesM * coeff(:,4) * 0.0;
    
    %compV = max(compV) - compV; % reverse intensities
    
    compV(nanIntenityV) = min(compV);
    comp3M = reshape(compV,siz);
    
    % figure, imagesc(comp3M(:,:,30))
    % figure, imagesc(volToEval(:,:,30))
    
    
    %%% AA commented for writing cropped CT scans ends
    
    %%
    % Save comp3M to planC
    %dose2CERR(entropy3M,[], 'entropy3voxls_Ins3_NI14','test','test','non CT',regParamsS,'no',assocScanUID)
    planC = scan2CERR(comp3M,['PC_',num2str(compNum)],'Passed',regParamsS,assocTextureUID,planC);
    % planC = scan2CERR(volToEval,'PC','Passed',regParamsS,assocTextureUID,planC);
    
end

% for iFeat = 1:size(newFeaturesM,2)
%     compV = zeros(prod(siz),1);
%     compV(nanIntenityV) = min(compV);
%     compV(~nanIntenityV) = newFeaturesM(:,iFeat);
%         planC = scan2CERR(reshape(compV,siz),['Feat_',num2str(iFeat)],'Passed',regParamsS,assocTextureUID,planC);
% end

