function [procMask3M, planC] = post_process_chewing_structs(strNum,paramS,planC)
% AI 10/1/19
% Morphological post-processing for auto-segmentation of chewing structures.
%--------------------------------------------------------------------------

%Get auto-segemented mask
[label3M, planC] = getStrMask(strNum,planC);
slicesV = find(squeeze(sum(sum(double(label3M)))>0));

maskSiz = size(label3M,1);
scale = 512/maskSiz;

%Post-process
if ~isempty(slicesV)
    
    filtSize = floor(3/scale);
    filtSize = max(1,2*floor(filtSize/2)-1); %Nearest odd val.
    
    conn = 26;
    
    strMask3M = zeros(size(label3M,1),size(label3M,1),length(slicesV));
    sliceLabels3M = label3M(:,:,slicesV);
    
    %Fill holes
    sliceLabels3M = imclose(sliceLabels3M,strel('sphere',floor(5/scale)));
    
    %Remove islands
    for s = 1:size(sliceLabels3M,3)
        slcMask = sliceLabels3M(:,:,s);
        sliceLabels3M(:,:,s) = bwareaopen(slcMask,floor(10/scale^2),8);
        temp = sliceLabels3M(:,:,s);
        strMaskM = zeros(size(temp));
        connCompS = bwconncomp(temp,8);
        ccSiz = cellfun(@numel,[connCompS.PixelIdxList]);
        sel = ccSiz==max(ccSiz);
        if ~ (isempty(temp(sel)) | max(ccSiz)< floor(10/scale^2))
            idx = connCompS.PixelIdxList{sel};
            strMaskM(idx) = 1;
        end
        sliceLabels3M(:,:,s) = strMaskM;
    end
    
    %Retain largest connected component
    connCompS = bwconncomp(sliceLabels3M,conn);
    ccSiz = cellfun(@numel,[connCompS.PixelIdxList]);
    sel = ccSiz==max(ccSiz);
    if ~ (isempty(sliceLabels3M(sel)) | max(ccSiz)< floor(1000/scale^2)) 
        idx = connCompS.PixelIdxList{sel};
        strMask3M(idx) = 1;
    end
    
    %Smooth
    smoothedlabel3M = smooth3(double(strMask3M),'box',filtSize);
    strMask3M = smoothedlabel3M > 0.4;
    
    
    label3M(:,:,slicesV) = strMask3M;
    
end

procMask3M = label3M;

end