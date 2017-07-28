% this script tests patchwise GLCM texture features between CERR and ITK.
%
% APA, 11/30/2016

% Number of Gray levels
nL = 16;

% Radius of the cubic patch
patchSiz = 1;

% Random n x n x n matrix
n = 20;
testM = rand(n,n,n);
testM = imquantize_cerr(testM,nL);
maskBoundingBox3M = testM .^0;

% % Structure from planC
% global planC
% indexS = planC{end};
% scanNum     = 1;
% structNum   = 16;
% 
% [rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
% [mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
% scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
% 
% SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
% [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
% maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
% volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
% volToEval(maskBoundingBox3M==0)     = NaN;
% 
% testM = imquantize_cerr(volToEval,nL);


% CERR texture
flagsV = ones(1,9); % all 9 features
patchSizeV = [1,1,1] * patchSiz;
offsetsM = getOffsets(1);
minIntensity = min(testM(:));
maxIntensity = max(testM(:));
separateDirnFlag = 0;
[energy3M,entropy3M,sumAvg3M,corr3M,invDiffMom3M,contrast3M, ...
    clustShade3M,clustPromin3M, haralCorr3M] = textureByPatch(testM,...
    nL,patchSizeV,offsetsM,flagsV,NaN,minIntensity,maxIntensity,separateDirnFlag);


%% ITK texture
cerrTestDir = getCERRPath;
cerrTestDir(end) = [];
if ispc
    slashType = '\';
else
    slashType = '/';
end
slashV = strfind(cerrTestDir, slashType);
cerrTestDir = cerrTestDir(1:slashV(end)-1);
cerrTestDir = fullfile(cerrTestDir,'Unit_Testing','tests_for_cerr');

patchGlcmDir = fullfile(cerrTestDir,'PatchwiseGlcmFeatures','win7');
resolution = [1 1 1]; % dummy resolution.
offset = [0 0 0];
scanFileName = fullfile(cerrTestDir,'mhaData','test1.mha');
test1M = permute(testM, [2 1 3]); % required to match coordinate system ...
%... between CERR and DICOm
test1M = flipdim(test1M,3);
delete(scanFileName)
writemetaimagefile(scanFileName, (test1M), resolution, offset)

% run ITK's textutre calculation
cd(patchGlcmDir)
tic
system([fullfile(patchGlcmDir,'PatchwiseGlcmFeatures'), ' ', scanFileName, ' ', num2str(nL),' 1 ',...
    num2str(nL),' ', num2str(patchSiz)])
toc


% direction order from ITK:
orderV = [11, 13, 10, 12, 5, 8, 9, 7, 6, 4, 1, 2, 3]; % not used here ...
            % since we are comparing the means across all the directions

% Read ITK features
featuresC = {'Energy','Entropy','DiffMoment','Inertia',...
    'ClusterShade','ClusterProminence','Correlation','HaralickCorrelation'};
for iFeature = 1:length(featuresC)
    feature = featuresC{iFeature};
    featureFilesC = cell(1,12);
    for j = 0:12
        featureFilesC{j+1} = [feature,num2str(j)];
    end
    itkFeatureM = [];
    for i = 1:13
        fileName = fullfile(patchGlcmDir,[feature,num2str(i-1),'.mha']);
        [data3M,infoS] = readmha(fileName);
        if isempty(itkFeatureM)
            itkFeatureM = data3M;
        else
            itkFeatureM = itkFeatureM + data3M;
        end
    end
    itkFeatureM = itkFeatureM / 13;
    itkFeatureM = flipdim(permute(itkFeatureM,[2,1,3]),3);
    
    % Retain only the part ofmatrix matrix which is
    % in the valid calculation region
    itkFeatureM = itkFeatureM(patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz);
    
    switch lower(feature)
        
        case 'energy'
            energyDiff3M = (itkFeatureM - ...
                energy3M(patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz))./...
                itkFeatureM*100;
            
        case 'entropy'
            entropyDiff3M = (itkFeatureM - ...
                entropy3M(patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz))./...
                itkFeatureM*100;
            
        case 'diffmoment'
            diffMomDiff3M = (itkFeatureM - ...
                invDiffMom3M(patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz))./...
                itkFeatureM*100;           
                        
        case 'inertia'
            inertiaDiff3M = (itkFeatureM - ...
                contrast3M(patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz))./...
                itkFeatureM*100;            
            
        case 'clustershade'
            clustShadeDiff3M = (itkFeatureM - ...
                clustShade3M(patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz))./...
                itkFeatureM*100;             
                       
        case 'clusterprominence'
            clustPromDiff3M = (itkFeatureM - ...
                clustPromin3M(patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz))./...
                itkFeatureM*100;            

        case 'correlation'
            corrDiff3M = (itkFeatureM - ...
                corr3M(patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz))./...
                itkFeatureM*100;                      

        case 'haralickcorrelation'
            haralCorrDiff3M = (itkFeatureM - ...
                haralCorr3M(patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz,...
                patchSiz+1:end-patchSiz))./...
                itkFeatureM*100;           
            
    end
    
end

% Compute max difference in all the features
maxEnergyDiff = max(energyDiff3M(:));
maxEntropyDiff = max(entropyDiff3M(:));
maxMomDiff = max(diffMomDiff3M(:));
maxInertiaDiff = max(inertiaDiff3M(:));
maxClustShadeDiff = max(clustShadeDiff3M(:));
maxClustPromDiff = max(clustPromDiff3M(:));
maxCorrDiff = max(corrDiff3M(:));
maxHaralCorrDiff = max(haralCorrDiff3M(:));



disp('========= Maximum difference between features for all 13 directions ==========')
disp(['Energy: ', sprintf('%0.1e',maxEnergyDiff), ' %'])
disp(['Entropy: ', sprintf('%0.1e',maxEntropyDiff), ' %'])
disp(['InverseDiffMoment: ', sprintf('%0.1e',maxMomDiff), ' %'])
disp(['Inertia: ', sprintf('%0.1e',maxInertiaDiff), ' %'])
disp(['Cluster Shade: ', sprintf('%0.1e',maxClustShadeDiff), ' %'])
disp(['Cluster Prominance: ', sprintf('%0.1e',maxClustPromDiff), ' %'])
disp(['Correlation: ', sprintf('%0.1e',maxCorrDiff), ' %'])
disp(['Haralick Correlation: ', sprintf('%0.1e',maxHaralCorrDiff), ' %'])


