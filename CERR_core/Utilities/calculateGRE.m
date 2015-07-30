% Absolute Difference between two scans
siz = size(planC{indexS.scan}(1).scanArray);
baseMask3M = logical(maskByThresh3D(planC{indexS.scan}(1).scanArray));
movMask3M = logical(maskByThresh3D(planC{indexS.scan}(2).scanArray));
sA1 = zeros(siz,'single');
meanSa1 = mean(single(planC{indexS.scan}(1).scanArray(baseMask3M)));
sdSa1 = std(single(planC{indexS.scan}(1).scanArray(baseMask3M)));
sA1(baseMask3M) = (single(planC{indexS.scan}(1).scanArray(baseMask3M)) - meanSa1)/sdSa1;
sA2 = zeros(siz,'single');
meanSa2 = mean(single(planC{indexS.scan}(2).scanArray(movMask3M)));
sdSa2 = std(single(planC{indexS.scan}(2).scanArray(movMask3M)));
sA2(movMask3M) = (single(planC{indexS.scan}(2).scanArray(movMask3M)) - meanSa2)/sdSa2;
diff3M = abs(sA1 - sA2);

% Window size
slcWindow = 5;
rowWindow = 5;
colWindow = 5;

% Number of levels for histogram
numLevels = 16;
% Create initial imM with dimension of slcWindow
imM = [];
for slc = 1:slcWindow
    imTmpM = im2col(diff3M(:,:,slc),[rowWindow colWindow],'sliding');
    imM = [imM;imTmpM];
end

numNeighbors = rowWindow*colWindow;
numSlcs = size(diff3M,3);
numRows = size(diff3M,1);
numCols = size(diff3M,2);
entropy3M = zeros(siz,'single');
mean3M = zeros(siz,'single');
var3M = zeros(siz,'single');
for slc = 1:numSlcs
    disp(['-------------------', num2str(slc)])
    if slc > floor(slcWindow/2) && slc <= (numSlcs-floor(slcWindow/2))
        imM(1:numNeighbors,:) = [];
        imTmpM = im2col(diff3M(:,:,slc),[rowWindow colWindow],'sliding');
        imM = [imM;imTmpM];
    end
    countsM = hist(imM,numLevels);
    countsM = countsM/numNeighbors/colWindow;
    entrpy2M = col2im(-sum(countsM.*log2(countsM+eps)),[rowWindow colWindow],[numRows numCols],'sliding');
    mean2M = col2im(mean(imM),[rowWindow colWindow],[numRows numCols],'sliding');
    var2M = col2im(var(imM),[rowWindow colWindow],[numRows numCols],'sliding');
    for i = 1:floor(slcWindow/2)
        entrpy2M = [entrpy2M(:,1), entrpy2M, entrpy2M(:,end)];
        entrpy2M = [entrpy2M(1,:); entrpy2M; entrpy2M(end,:)];
        mean2M = [mean2M(:,1), mean2M, mean2M(:,end)];
        mean2M = [mean2M(1,:); mean2M; mean2M(end,:)];
        var2M = [var2M(:,1), var2M, var2M(:,end)];
        var2M = [var2M(1,:); var2M; var2M(end,:)];
    end
    entropy3M(:,:,slc) = entrpy2M;
    mean3M(:,:,slc) = mean2M;
    var3M(:,:,slc) = var2M;
end

gre3M = entropy3M/median(entropy3M(baseMask3M)) + mean3M/median(mean3M(baseMask3M)) + var3M/median(var3M(baseMask3M));
gre3M = gre3M / 3;

% 
showIMDose(diff3M,'Diff',1);
showIMDose(entropy3M,'Entropy',1);
showIMDose(mean3M,'Mean',1);
showIMDose(var3M,'Variance',1);
showIMDose(gre3M,'GRE',1);



