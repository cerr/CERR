function featureS = getInterTumorHeteroFeature(structNumV,planC)
% function featureS = getInterTumorHeteroFeature(structNumV,planC)
%
% This function computes inter-tumor heterogeneity features based on
% Veeraraghavan et al.
%
% Reference:
% Computed Tomography Measures of Inter-site tumor Heterogeneity for 
% Classifying Outcomes in High-Grade Serous Ovarian Carcinoma: 
% a Retrospective Study, Harini Veeraraghavan, Hebert Alberto Vargas, 
% Alejandro Jimenez Sanchez, Maura Micco, Eralda Mema, Marinela Capanu, 
% Junting Zheng, Yulia Lakhman, Mireia Crispin-Ortuzar, Erich Huang, 
% Douglas A Levine, Joseph O Deasy, Alexandra Snyder, Martin L Miller, 
% James D Brenton, Evis Sala, bioRxiv 531046; doi: https://doi.org/10.1101/531046
%
% APA, 5/20/2017
%
% based on H. Veeraraghavan.

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

% parameters
filterType = 'HaralickCooccurance';
textureParamS.Type.val = 'all';
textureParamS.Directionality.val = 2; %1:'3d'; %2:'2d';
textureParamS.NumLevels.val = 32;
textureParamS.binWidth.val = [];
textureParamS.minIntensity.val = [];
textureParamS.maxIntensity.val = [];
textureParamS.PatchSize.val = [2 2 0];
haralickTextFeatNameC = {'Energy','Entropy','Contrast','Corr','InvDiffMom'};
ncenters = 5;


siteClusterFeats = []; %zeros(nlabels*ncenters, nfeats);

scanNumV = getStructureAssociatedScan(structNumV,planC);
if length(unique(scanNumV)) ~= 1
    featureS = [];
    return;
end

scanNum = scanNumV(1);
scan3M = getScanArray(planC{indexS.scan}(scanNum));
scan3M = double(scan3M) - ...
    planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;


numStructs = length(structNumV);

for iStr = 1 : numStructs
 
   structNum = structNumV(iStr);
   [rasterSegments, planC, isError] = getRasterSegments(structNum,planC);
   [mask3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
   simg = scan3M(:,:,uniqueSlices);
   
   fimg = repmat(zeros(size(simg),'single'),[1,1,1,6]);
   
   % Compute patch-wise texture
   outS = processImage(filterType,simg,mask3M,textureParamS,NaN);
   for indImgType = 1:length(haralickTextFeatNameC)
      fimg(:,:,:,indImgType) = outS.(haralickTextFeatNameC{indImgType});
   end
   
   % Include the original image as the last image
   fimg(:,:,:,6) = simg;
   
   I = find(mask3M);
   data = zeros(numel(I), size(fimg,4));
   cfeats = zeros(1, size(fimg,4));
    
    for f = 1 : size(fimg,4)
        fim = fimg(:,:,:,f);
        data(:,f) = fim(I);
        indxNoNan = find(~isnan(data(:,f)));
        if(~isempty(indxNoNan))
            cfeats(:,f) = mean(data(indxNoNan,f));
        end
    end
    clusters = zeros(numel(I),1);
    [v, indx] = find(cfeats ~= 0);
    sdata1 = data(:,indx);
   
    %[~,~,cIndx] = doClustering('kmeans', sdata1, 5, [], 1);
    cIndx = kmeans(sdata1, ncenters);
    cIndx = cIndx';
    ulabels = unique(cIndx);
    for c = 1 : numel(ulabels)
        indx = find(cIndx == ulabels(c));
        clusters(indx) = c;
    end

    disp('Done clustering...');
    clabels = unique(clusters);
    cfeats = zeros(numel(clabels),size(data,2));
    for i1 = 1 : numel(clabels)
        indx = find(clusters==clabels(i1));
        cfeats(i1,:) = mean(data(indx,:));
    end
    siteClusterFeats = [siteClusterFeats; cfeats];    
end


disp(siteClusterFeats);

disp('Computing affinity matrix');


clabels = size(siteClusterFeats,1);


affmat = zeros(clabels);
for i1 = 1 : clabels
    for j1 = i1+1 : clabels
        %distance = pdist2(siteClusterFeats(i1,:), siteClusterFeats(j1,:), 'sqeuclidean');
        distance = sum((siteClusterFeats(i1,:) - siteClusterFeats(j1,:)).^2);
        affmat(i1,j1) = distance;
        affmat(j1,i1) = affmat(i1,j1);
    end
end

disp('Computing the ISTH measures..');
try

   maxdist = 0.0;
   mindist = 0.0;
   for n = 1 : clabels
        if(max(max(affmat)) > maxdist)
            maxdist = max(max(affmat));
        end
   end

    for n = 1 : clabels 
       amat = min(1,(affmat - mindist)./(maxdist-mindist)).*256;
    end
    %[cSE, cluVar, cluDiss] = computeAffMatCharacteristics(amat);  
    [cSE, cluVar, cluDiss] = computeAffMatChars(amat); 
    featureS.cSE = cSE;
    featureS.cluVar = cluVar;
    featureS.cluDiss = cluDiss;
        
catch err
     disp('Error in computing the affinity matrix');
     cSE = 0.0;
     cluVar = 0.0;
     cluDiss = 0.0;
end

