function [procMask3M, planC] = post_process_constrictor(strNum,paramS,planC)
% AI 10/1/19
% Morphological post-processing for auto-segmentation of constrictor muscle.
%--------------------------------------------------------------------------

%Get auto-segemented mask
label3M = getStrMask(strNum,planC);
slicesV = find(squeeze(sum(sum(double(label3M)))>0));

%Post-process
if ~isempty(slicesV)
    
    conn = 26;
    filtSize = 3;
    
    sliceListV = slicesV(1):slicesV(end);
    strMask3M = zeros(size(label3M,1),size(label3M,1),length(slicesV));
    sliceLabels3M = label3M(:,:,slicesV);
    
    sliceLabels3M = imclose(sliceLabels3M,strel('sphere',4));
    
    %Retain largest connected component
    connCompS = bwconncomp(sliceLabels3M,conn);
    ccSiz = cellfun(@numel,[connCompS.PixelIdxList]);
    sel = ccSiz==max(ccSiz);
    if ~ (isempty(sliceLabels3M(sel)) | max(ccSiz)< 50)
        idx = connCompS.PixelIdxList{sel};
        strMask3M(idx) = 1;
    end
    
    %Fill holes and remove islands
    for n = 1:size(strMask3M,3)
        
        strMaskM = strMask3M(:,:,n);
        labelM = imclose(strMaskM,strel('disk',2));
        cc = bwconncomp(labelM);
        ccSiz = cellfun(@numel,[cc.PixelIdxList]);
        sel = ccSiz==max(ccSiz);
        if ~ (isempty(sliceLabels3M(sel)) | max(ccSiz)< 20)
            idx = cc.PixelIdxList{sel};
            labelM = zeros(size(labelM));
            labelM(idx) = 1;
            strMask3M(:,:,n) = labelM;
        else
            strMask3M(:,:,n) = zeros(size(labelM));
        end
        
    end
    
    %Smooth
    smoothedlabel3M = smooth3(double(strMask3M),'box',filtSize);
    strMask3M = smoothedlabel3M > 0.5;
    label3M(:,:,slicesV) = strMask3M;
    
end

procMask3M = label3M;