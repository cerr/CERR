function sclMask3M = perturbImageVolume(mask3M,scale)
% function sclMask3M = perturbImageVolume(mask3M,scale)
%
% Scales mask3M by amount scale.
%
% APA, 2/25/2019


sclMask3M = zeros(size(mask3M),'like',mask3M);
sizV = size(mask3M);
iCtr = round(sizV(1)/2);
jCtr = round(sizV(2)/2);
% scale = normrnd(0,2,1);
for slc = 1:size(mask3M,3)
%     sizV = size(mask3M(:,:,slc));
%     [iV,jV] = find3d(mask3M(:,:,slc));
%     maskM = mask3M(min(iV):max(iV),min(jV):max(jV),slc);
    maskM = mask3M(:,:,slc);
%     di = max(iV) - min(iV);
%     dj = max(jV) - min(jV);
%     iCtr = ceil((max(iV) + min(iV))/2);
%     jCtr = ceil((max(jV) + min(jV))/2);
%     minRow = -di*pctJitter/100;
%     maxRow = di*pctJitter/100;
%     minCol = -dj*pctJitter/100;
%     maxCol = dj*pctJitter/100;
%     numRows = minRow + (maxRow-minRow)*rand(1);
%     numCols = minCol + (maxCol-minCol)*rand(1);
%     minAng = -pctJitter/100*180;
%     maxAng = pctJitter/100*180;
%     angl = minAng + (maxAng-minAng)*rand(1);
%     scl = (100-pctJitter)/100 + 2*pctJitter/100*rand(1);
%     maskM = imtranslate(maskM,[numRows,numCols],'nearest','FillValues',0);
%     maskM = imrotate(maskM,angl,'bilinear');
    maskM = imresize(maskM, scale, 'nearest');
    newSiz = size(maskM);
    iStart = 1;
    jStart = 1;
    iEnd = 0;
    jEnd = 0;
    iMin = iCtr - ceil(newSiz(1)/2);
    if iMin < 0
        iStart = 1-iMin;
        iMin = 1;
    else
        iMin = iMin + 1;
    end
    iMax = iCtr + floor(newSiz(1)/2);
    if iMax > sizV(1)
        iEnd = iMax - sizV(1);
        iMax = sizV(1);
    end
    jMin = jCtr - ceil(newSiz(2)/2);
    if jMin < 0
        jStart = 1-jMin;
        jMin = 1;
    else
        jMin = jMin + 1;
    end
    jMax = jCtr + floor(newSiz(2)/2);
    if jMax > sizV(2)
        jEnd = jMax - sizV(2);
        jMax = sizV(2);
    end
    %mask3M(:,:,slc) = 0;
    sclMask3M(iMin:iMax,jMin:jMax,slc) = maskM(iStart:end-iEnd,jStart:end-jEnd);
end
