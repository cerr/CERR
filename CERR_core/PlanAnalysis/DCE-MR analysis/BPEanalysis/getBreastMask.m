function [bboxLeft3M,bboxRight3M] = getBreastMask(scan3M)
% AI 1/16/18

%Get no. of slices,rows,  cols
nSlices = size(scan3M,3);
nCol = size(scan3M,2);
nRow = size(scan3M,1);
airTh = 400;
tol = 0;
filt = gausswin(13,1.5);
filt = filt./sum(filt(:));

%Loop over slices
bboxLeft3M = false(size(scan3M));
bboxRight3M = false(size(scan3M));
fVoxV = nan(1,nSlices);
bsizeV = nan(1,nSlices);

for i = 1: nSlices
    
    sliceM = scan3M(:,:,i);
    
    %Get index of last voxel in each column with inensity > threshold
    th_maskM = sliceM>airTh;
    th_maskM = bwareaopen(th_maskM,50);
    
    fVoxV(i) = nnz(th_maskM(:))/numel(th_maskM(:));
    rowIdxV = nan(nCol,1);
    for j = 1 : nCol
        idx = find(th_maskM(:,j),1,'last');
        if ~isempty(idx)
            rowIdxV(j) = idx;
        end
    end
    colIdxV = [1:nCol].';
    % startCol = find(~isnan(rowIdxV),1);
    % endCol = find(~isnan(rowIdxV),1,'last');
    
    try
        
        %Smooth outline
        outlineV = smooth(colIdxV,rowIdxV,'rlowess');
        
        %Find peaks
        outSmoothV = conv(outlineV,filt,'same');
        [~,boundsV] = findpeaks(outSmoothV,'MinPeakProminence',10,'SortStr','descend');
        boundsV = sort(boundsV(1:2));
        
        %Find valley between peaks
        flipSigV = nRow-outlineV(boundsV(1):boundsV(2));
        [~,locV] = findpeaks(flipSigV,'MinPeakProminence',30,'SortStr','descend');
        if isempty(locV)
            [~,locV] = findpeaks(flipSigV,'SortStr','descend');
        end
        loc = locV(1) + boundsV(1);
        rowLim = outlineV(loc);
        rowLim = rowLim-tol;
        
        % --- For testing ----
        %Display
        %   figure,scatter(colIdxV,rowIdxV,'bo'),axis([1 nCol 1 nRow]);
        %   hold on
        %   plot(colIdxV,outlineV,'--r')
        %---------------------
        
        outlineV(outlineV<rowLim) = rowLim;
        bsizeV(i) = max(outlineV)- rowLim;
        
        %Create mask
        xV = [flipud(colIdxV);colIdxV];
        yV = [repmat(rowLim,nCol,1);outlineV];
        maskM = poly2mask(xV,yV,nRow,nCol) & th_maskM;
        maskM = bwareaopen(maskM,100);
        leftMaskM = maskM;
        leftMaskM(:,loc+1:end) = 0;
        rightMaskM = maskM;
        rightMaskM(:,1:loc) = 0;
        
        %Morphological processing
        leftMaskM = imfill(leftMaskM,'holes');
        leftMaskM = imclose(leftMaskM,strel('disk',4));
        rightMaskM = imfill(rightMaskM,'holes');
        rightMaskM = imclose(rightMaskM,strel('disk',4));
        
        bboxLeft3M(:,:,i) = leftMaskM;
        bboxRight3M(:,:,i) = rightMaskM;         
        
    catch
        
        fVoxV(i) = 0;
        bsizeV(i) = 0;

    end
end

%Plot size across slices
sliceV = 1:length(bsizeV);
% Smooth to remove sudden spikes
filtV = gausswin(64,10.5);                
filtV = filtV./sum(filtV);
smooth_bsizeV = medfilt1(bsizeV,10);         
smooth_bsizeV = conv(smooth_bsizeV,filtV,'same');   
% Get dir of change in size
diffV = diff(smooth_bsizeV);
signV = [0 sign(diffV)];         
signV = movmean(signV,10);             %Smooth

%Identify slices to retain
startsV = find([1,diff(signV)]);       %Starts of runs
runsV = diff(find([1,diff(signV),1])); %Lengths of runs
[runsV,orderV] = sort(runsV,'descend');
startsV = startsV(orderV);

% Find start slice
count = 0;
incFlag = 0;
while ~incFlag
    count = count+1;
    start1Idx = startsV(count);
    incFlag = signV(start1Idx)>0;
end
end1Idx = start1Idx+runsV(count)-1;
% Find end slice
run2IdxV = startsV>end1Idx;
startsV = startsV(run2IdxV);
runsV = runsV(run2IdxV);
count = 0;
decFlag = 0;
while ~decFlag
    count = count+1;
    start2Idx = startsV(count);
    decFlag = signV(start2Idx)<0;
end
end2Idx = start2Idx+runsV(count)-1;
minSizIdx = find(smooth_bsizeV(start2Idx:end2Idx)>= smooth_bsizeV(start1Idx)*.8,1,'last');
end2Idx = start2Idx + minSizIdx - 1;
keepSlicesV = start1Idx:end2Idx;
skipIdxV = ~ismember(sliceV,keepSlicesV);


% --- For testing (plot of bsizeV)----
% h = figure('visible','On');
% plot(sliceV,bsizeV,'-kx','lineWidth',1);
% axis([1 numel(sliceV),0,max(smooth_bsizeV)])
% hold on
% plot(sliceV,smooth_bsizeV,'--bx','lineWidth',1);
% line([start1Idx,start1Idx],[0,max(smooth_bsizeV)],'Color','r','LineStyle','--');
% line([end2Idx,end2Idx],[0,max(smooth_bsizeV)],'Color','r','LineStyle','--');
% xlabel('Size');
% ylabel('Slice #');
%----------------------------------

%Skip selected slices 
bboxLeft3M(:,:,skipIdxV) = false(size(scan3M,1),size(scan3M,2),nnz(skipIdxV));
bboxRight3M(:,:,skipIdxV) = false(size(scan3M,1),size(scan3M,2),nnz(skipIdxV));



end