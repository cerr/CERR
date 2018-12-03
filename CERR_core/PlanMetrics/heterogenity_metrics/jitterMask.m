function jtrMask3M = jitterMask(mask3M,pctJitter)
% function jtrMask3M = jitterMask(mask3M,pctJitter)
%
% Jitters the input mask3M by translation, rotation and scaling by a factor
% of pctJitter.
%
% Example:
% mask3M = rand(10,10,5)  0.5;
% pctJitter = 5; % percent
% jtrMask3M = jitterMask(mask3M,pctJitter);
%
% APA, 12/2/2018

% global planC
% indexS = planC{end};
% 
% structNum = 1;
% scanNum = 1;
% pctJitter = 5;
% 
% fullmaks3M = getUniformStr(structNum,planC);
% [rasterSegments, planC, isError] = getRasterSegments(structNum,planC);
% [mask3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);

jtrMask3M = zeros(size(mask3M),'like',mask3M);
for slc = 1:size(mask3M,3)
    fullSiz = size(mask3M(:,:,slc));
    [iV,jV] = find3d(mask3M(:,:,slc));
    maskM = mask3M(min(iV):max(iV),min(jV):max(jV),slc);
    di = max(iV) - min(iV);
    dj = max(jV) - min(jV);
    iCtr = ceil((max(iV) + min(iV))/2);
    jCtr = ceil((max(jV) + min(jV))/2);
    minRow = -di*pctJitter/100;
    maxRow = di*pctJitter/100;
    minCol = -dj*pctJitter/100;
    maxCol = dj*pctJitter/100;
    numRows = minRow + (maxRow-minRow)*rand(1);
    numCols = minCol + (maxCol-minCol)*rand(1);
    minAng = -pctJitter/100*180;
    maxAng = pctJitter/100*180;
    angl = minAng + (maxAng-minAng)*rand(1);
    scl = (100-pctJitter)/100 + 2*pctJitter/100*rand(1);
    maskM = imtranslate(maskM,[numRows,numCols],'nearest','FillValues',0);
    maskM = imrotate(maskM,angl,'nearest');
    maskM = imresize(maskM, scl, 'nearest');
    newSiz = size(maskM);
    iStart = 1;
    jStart = 1;
    iEnd = 0;
    jEnd = 0;
    iMin = iCtr - ceil(newSiz(1)/2);
    if iMin < 0
        iStart = 1-iMin;
        iMin = 1;
    end
    iMax = iCtr + floor(newSiz(1)/2) - 1;
    if iMax > fullSiz(1)
        iEnd = fullSiz(1) - iMax;
        iMax = fullSiz(1);
    end
    jMin = jCtr - ceil(newSiz(2)/2);
    if jMin < 0
        jStart = 1-jMin;
        jMin = 1;
    end
    jMax = jCtr + floor(newSiz(2)/2) - 1;
    if jMax > fullSiz(2)
        jEnd = fullSiz(2) - jMax;
        jMax = fullSiz(2);
    end
    %mask3M(:,:,slc) = 0;
    jtrMask3M(iMin:iMax,jMin:jMax,slc) = maskM(iStart:end-iEnd,jStart:end-jEnd);
end

% fullmaks3M(:,:,uniqueSlices) = mask3M;
% isUniform = 1;
% strname = [planC{indexS.structures}(structNum).structureName, '_Perturbed'];
% planC = maskToCERRStructure(fullmaks3M, isUniform, scanNum, strname, planC);

