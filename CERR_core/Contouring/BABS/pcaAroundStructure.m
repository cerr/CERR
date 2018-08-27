% pcaAroundStructure.m
%
% PCA using Law's and Haralick textures
%
% APA, 01/16/2017

% Define parameters to generate Texture and the PCAs

scanNum     = 1;
%structNum   = 3; % Left Parotid
structName  = 'Parotid_L_SvD'; % Structure name
structName  = 'Parotid_LT_Peng_No_Noise'; % Structure name
rowMargin = 10; % extend rows by this amount
colMargin = 10; % extend cols by this amount
slcMargin = 0; % extend slcss by this amount
minIntensity = -200;   % Clipping min
maxIntensity = 400; % Clipping max
dirName = 'H:\Public\Aditya\mimExtensions\CERR_files';
dirName = 'H:\Public\Aditya\mimExtensions\Atlas_no_noise';
%dirName = 'H:\Public\Aditya\mimExtensions\CERR_files_corrected_contours';
dirName = 'H:\Public\Aditya\mimExtensions\Atlas_Sanne\CT_cerr';
dirName = '/lab/deasylab1/Aditya/AtlasSeg/CT_cerr';
dirName = '/lab/deasylab1/Aditya/AtlasSeg/PengAtlas/CERR_files_Peng_Atlas';
dirName = 'L:\Aditya\AtlasSeg\PengAtlas\CERR_files_Peng_Atlas';

%hParPool = parpool(40);

% Iterate over all plans in the directory
dirS = dir(dirName);
dirS(1:2) = [];

% Initialize the features matrix (pre-allocate for speed, to do)
featuresM = [];
outV = [];

for planNum = 1:length(dirS)
    
    fileNam = fullfile(dirName,dirS(planNum).name);
    
    planC = loadPlanC(fileNam, tempdir);
    
    planC = quality_assure_planC(fileNam,planC);
    indexS = planC{end};
    
    if length(planC{indexS.scan}) > 1
        planC = deleteScan(planC, 1);
    end
    
    %global planC
    indexS = planC{end};
    
    % Find matching structure
%     structNum = getMatchingIndex([lower(structName),'_sf'],lower(...
%         {planC{indexS.structures}.structureName}),'exact');
%     if isempty(structNum)
        structNum = getMatchingIndex(lower(structName),lower(...
            {planC{indexS.structures}.structureName}),'exact');
%     end
    
    if isempty(structNum)
        continue;
    end
    
    if length(structNum) > 1
        structNum = structNum(1);
    end
    
    % Get Law's and Haralick features for this structure
    harOnlyFlg = 0;
    featFlagsV = [1,1,1,1,1,1,1,1,1];
    numLevsV = 64;
    patchRadiusV = [1,2];
    featuresForPlanM = getLawsAndHaralickFeatures(structNum,...
        rowMargin,colMargin,slcMargin,minIntensity,maxIntensity,planC,...
        harOnlyFlg,featFlagsV,numLevsV,patchRadiusV);
    
    featuresM = [featuresM; featuresForPlanM];
    
    [volToEval,maskBoundingBox3M,mask3M,minr,maxr,minc,maxc,mins,maxs] = ...
        getROI(structNum,rowMargin,colMargin,slcMargin,planC);
    %mask3M(volToEval < -400) = [];    
    %outV = [outV; double(mask3M(:))];    
    
end  % plans

% standardize features
featureMeanV = mean(featuresM);
featureStdV = std(featuresM);
featuresM = bsxfun(@minus,featuresM, featureMeanV);
featuresM = bsxfun(@rdivide,featuresM, featureStdV);

% PCA
% indSignifV = [9    47    61   186   187   191   192   195   196   197   200   201   202   205   206   207   210   211 ...
%    212   215   216   217   220   221   222   225   226   227   230]; %
%    [-100 300] HU
indSignifV = 1:size(featuresM,2);
[coeff,score,latVar] = pca(featuresM(:,indSignifV),'NumComponents',73);

%[XLOADINGS,YLOADINGS,XSCORES,YSCORES] = plsregress(featuresM(:,indSignifV),outV,10);


% [volToEval,maskBoundingBox3M,mask3M,minr,maxr,minc,maxc,mins,maxs] = ...
%     getROI(structNum,rowMargin,colMargin,slcMargin,planC);
% outM = mask3M(volToEval >= -400);
% Y = double(outM(:));
% Y = (Y - mean(Y)) / std(Y);
% 
% sampleSize = 10000;
% dim = 1;
% numBootSamples = 40;
% [featuresBootM, indBootV] = datasample(featuresM,sampleSize,1);
% Yboot = Y(indBootV);
% Yboot = (Yboot - mean(Yboot)) / std(Yboot);
% featuresBootM = bsxfun(@minus,featuresBootM, mean(featuresBootM,1));
% featuresBootM = bsxfun(@rdivide,featuresBootM, std(featuresBootM,1));
% [B,V,U,se2,Sf] = SupPCA(Yboot,featuresBootM,10);

%save('pca_haralick_only_64_levs_1_2_patchRad.mat','coeff','latVar','featureMeanV','featureStdV','-v7.3') % used for all trial till now (7/11/2018).
save('pca_laws_wavlet.mat','coeff','latVar','featureMeanV','featureStdV','-v7.3') % used for all trial till now (7/11/2018).

% Plot explained variance
figure, plot(cumsum(latVar)./sum(latVar)*100,'linewidth',2)
xlabel('Number of components','fontsize',20)
ylabel('Explained variance','fontsize',20)
set(gca,'fontsize',20)

% Feature importance score
figure, plot(coeff(:,1),'ro')
xlabel('Feature','fontsize',20)
ylabel('Weight','fontsize',20)
set(gca,'fontsize',20)

% Apply the PCA to new dataset

rowMargin = 10; % extend rows by this amount
colMargin = 10; % extend cols by this amount
slcMargin = 0; % extend slcss by this amount

% featureMeanV = mean(featureMeanM);
% featureStdV = mean(featureStdM);
% coeff = mean(coeff3M)';

% Load planC
newPlanNum = 7;
fileNam = fullfile(dirName,dirS(newPlanNum).name);
planC = loadPlanC(fileNam, tempdir);
planC = quality_assure_planC(fileNam,planC);
indexS = planC{end};
if length(planC{indexS.scan}) > 1
    planC = deleteScan(planC, 1);
end

% Find matching structure
structNum = getMatchingIndex(lower(structName),lower(...
    {planC{indexS.structures}.structureName}),'exact');
if length(structNum) > 1
    structNum = structNum(1);
end

% Get Law's and Haralick features for this structure
newFeaturesM = getLawsAndHaralickFeatures(structNum,...
    rowMargin,colMargin,slcMargin,minIntensity,maxIntensity,planC);

newFeaturesM = getLawsAndHaralickFeatures(structNum,...
        rowMargin,colMargin,slcMargin,minIntensity,maxIntensity,planC,...
        harOnlyFlg,featFlagsV,numLevsV,patchRadiusV);
    
newFeaturesM = bsxfun(@minus,newFeaturesM, featureMeanV);
newFeaturesM = bsxfun(@rdivide,newFeaturesM, featureStdV);
newFeaturesM = newFeaturesM(:,indSignifV);

% get ROI
[volToEval,maskBoundingBox3M,mask3M,minr,maxr,minc,maxc,mins,maxs] = ...
    getROI(structNum,rowMargin,colMargin,slcMargin,planC);
% Clip intensities
%volToEval(volToEval < minIntensity) = minIntensity;
%volToEval(volToEval > maxIntensity) = maxIntensity;

%% Component Number
compNum = 2;

% Get Component image in 3d
compV = 1*newFeaturesM * coeff(:,1) + 0*newFeaturesM * coeff(:,2);
% compV = 1*newFeaturesM * coeff(:,1);
% minVal = min(compV);
% if minVal > 0
%     minVal = 0;
% end
% compV = minVal + 2.2*newFeaturesM * coeff(:,2);

% compV = 0*newFeaturesM * XLOADINGS(:,1) + ...
%     0*newFeaturesM * XLOADINGS(:,2) + ...
%     1*newFeaturesM * XLOADINGS(:,3);
compM = zeros(size(volToEval),'double');
minVal = min(compV);
valToAddM = zeros(size(volToEval),'double');
compM(volToEval >= -400) = -minVal + compV;
% valToAddM(volToEval > 400) = volToEval(volToEval > 400);
% compM = compM + valToAddM/max(valToAddM(:))*max(compM(:))*0.25;
%compM = imgaussfilt(compM,0.5);

%% Plot components, raw image and segmentation
slcNum = 15;
map = CERRColorMap('gray256');
%compSlcM = (-minVal+compM(:,:,slcNum)) .* double(volToEval(:,:,slcNum) > -200);
compSlcM = compM(:,:,slcNum);
figure, imagesc(compSlcM), colormap(map)
%figure, imagesc(clustM(:,:,slcNum)), colormap(map)
figure, imagesc(volToEval(:,:,slcNum)), colormap(map)
figure, imagesc(mask3M(:,:,slcNum)), colormap(map)

%%
map = CERRColorMap('gray256');
%map = flipud(map);
figure,
for i = 1:16
    comp1M = zeros(size(maskBoundingBox3M));
    compV = 1*newFeaturesM * coeff(:,i);
    compV = imcomplement(compV);
    minVal = min(compV);
    comp1M(volToEval >= -400) = -minVal + compV;
    %comp1M(maskBoundingBox3M) = score(:,3)/1e5;
    %comp1M(:) = score(:,1);
    %figure, imagesc(comp1M(:,:,20))
    %comp1M = volToEval;
    subplot(4,4,i), imagesc(comp1M(:,:,slcNum)), title(['PCA: ',num2str(i)])
    axis equal, colormap(map)
    axis off
end

% comp1M = NaN*ones(size(maskBoundingBox3M));
% comp1M(maskBoundingBox3M) = score(:,2);
% figure, hist(comp1M(:),30)
% title('Component 2','fontsize',20)






