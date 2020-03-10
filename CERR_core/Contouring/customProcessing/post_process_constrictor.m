function procMask3M = post_process_cm(strNum,paramS,planC)
% AI 10/1/19
% Morphological post-processing for auto-segmentation of constrictor muscle.
%--------------------------------------------------------------------------

%Get auto-segemented mask
mask3M = getStrMask(strNum,planC);
procMask3M = zeros(size(mask3M));
labelV = unique(mask3M);
conn = 26;


for l = 2:length(labelV) %labelV(1) = 0;
    
    strMask3M = zeros(size(mask3M));
    
    label3M = mask3M == l-1;
    
    %Fill holes
    label3M = imfill(label3M,conn,'holes');
    
    %Fuse disjointed segments
    for n = 1:size(label3M,3)
        
        labelM = double(label3M(:,:,n)== l-1);
        labelM = imclose(labelM,strel('disk',4)); 
        label3M(:,:,n) = labelM;
        
    end
    
    %Retain largest connected component
    connCompS = bwconncomp(label3M,conn);
    ccSiz = cellfun(@numel,[connCompS.PixelIdxList]);
    sel = ccSiz==max(ccSiz);
    if ~ (isempty(label3M(sel)) | max(ccSiz)< 50)
        idx = connCompS.PixelIdxList{sel};
        strMask3M(idx) = l-1;
    end
    
    %Morph proc
    for n = 1:size(strMask3M,3)
        
        %strMaskM = strMask3M(:,:,n);
        strMaskM = double(strMask3M(:,:,n)== l-1);
        
        
        labelM = imclose(strMaskM,strel('disk',2)); 
        labelM = imfill(labelM,'holes');
        
        cc = bwconncomp(labelM);
        ccSiz = cellfun(@numel,[cc.PixelIdxList]);
        sel = ccSiz==max(ccSiz);
        if ~ (isempty(label3M(sel)) | max(ccSiz)< 20)
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