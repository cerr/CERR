function [procMask3M, planC] = post_process_larynx(strNum,paramS,planC)
% AI 03/26/2020
% Morphological post-processing for auto-segmentation of larynx.
%--------------------------------------------------------------------------

%Get auto-segemented mask
[label3M, planC] = getStrMask(strNum,planC);
slicesV = find(squeeze(sum(sum(double(label3M)))>0));

%Create morph. structuring elements
S1 = makeSphereStrel(3);

%Post-process
if ~isempty(slicesV)
    
    filtSize = 5;
    conn = 26;
    
    strMask3M = zeros(size(label3M,1),size(label3M,1),length(slicesV));
    sliceLabels3M = label3M(:,:,slicesV);
    
    %Fill holes
    sliceLabels3M = imclose(sliceLabels3M,S1);
    
    %Remove islands
    for s = 1:size(sliceLabels3M,3)
        slcMask = sliceLabels3M(:,:,s);
        slcMask = bwareaopen(slcMask,10,8);
        strMaskM = zeros(size(slcMask));
        connCompS = bwconncomp(slcMask,8);
        ccSiz = cellfun(@numel,[connCompS.PixelIdxList]);
        sel = ccSiz==max(ccSiz);
        if ~ (isempty(slcMask(sel)) | max(ccSiz)< 20)
            idx = connCompS.PixelIdxList{sel};
            strMaskM(idx) = 1;
        end
        sliceLabels3M(:,:,s) = strMaskM;
    end
    
    %Retain largest connected component
    connCompS = bwconncomp(sliceLabels3M,conn);
    ccSiz = cellfun(@numel,[connCompS.PixelIdxList]);
    sel = ccSiz==max(ccSiz);
    if ~ (isempty(sliceLabels3M(sel)) | max(ccSiz)< 1000)
        idx = connCompS.PixelIdxList{sel};
        strMask3M(idx) = 1;
    end
    
    %Smooth
    smoothedlabel3M = smooth3(double(strMask3M),'box',filtSize);
    strMask3M = smoothedlabel3M > 0.5; 
    
    label3M(:,:,slicesV) = strMask3M;
    
end

procMask3M = label3M;


end