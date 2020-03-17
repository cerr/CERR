function procMask3M = post_process_chewing_structs(strNum,paramS,planC)
% AI 10/1/19
% Morphological post-processing for auto-segmentation of chewing structures.
%--------------------------------------------------------------------------

%Get auto-segemented mask
mask3M = getStrMask(strNum,planC);
procMask3M = zeros(size(mask3M));
labelV = [0 1 2 3 4];
conn = 26;

for l = 2:length(labelV) 
    
    strMask3M = zeros(size(mask3M));
    
    label3M = mask3M == l-1;
    
    %Fill holes
    label3M = imfill(label3M,conn,'holes');
    
    %Retain largest connected component
    connCompS = bwconncomp(label3M,conn);
    ccSiz = cellfun(@numel,[connCompS.PixelIdxList]);
    sel = ccSiz==max(ccSiz);
    if ~ (isempty(label3M(sel)) | max(ccSiz)< 1000) %for larynx, mm, pm
        idx = connCompS.PixelIdxList{sel};
        strMask3M(idx) = l-1;
    end
    
    %Morph proc
    for n = 1:size(strMask3M,3)
        
        strMaskM = double(strMask3M(:,:,n)== l-1);
        
        
        labelM = imopen(strMaskM,strel('disk',2)); %for larynx, mm,pm
        labelM = imfill(labelM,'holes');
        
        cc = bwconncomp(labelM);
        ccSiz = cellfun(@numel,[cc.PixelIdxList]);
        sel = ccSiz==max(ccSiz);
        if ~ (isempty(label3M(sel)) | max(ccSiz)< 5)
            idx = cc.PixelIdxList{sel};
            labelM = zeros(size(labelM));
            labelM(idx) = l-1;
            strMask3M(:,:,n) = labelM;
        else
            strMask3M(:,:,n) = zeros(size(labelM));
        end
        
    end
    
    
    procMask3M =  procMask3M + strMask3M;
    
end



end