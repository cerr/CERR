function neighbM = getImageNeighbours(scan3M,bboxDimV,rowWindow,colWindow)
% Get indices of neighbours for voxels within a bounding box
%-------------------------------------------------------------------------
% INPUTS
%scan3M        : Scan array
%bboxDimV      : bboxDimV = [minr,maxr,minc,maxc,mins,maxs];
%rowWindow     : No. rows defining neighbourhood around each voxel
%colWindow     : No. cols defining neighbourhood
%-------------------------------------------------------------------------
% AI 09/27/17 

%Pad the bounding box by [numRowsPad,numColsPad]
numColsPad = floor(colWindow/2);
numRowsPad = floor(rowWindow/2);
Iexp = scan3M(bboxDimV(1) - numRowsPad:bboxDimV(2) + numRowsPad,...
    bboxDimV(3)- numColsPad:bboxDimV(4) + numColsPad,...
    bboxDimV(5):bboxDimV(6));

%Create indices for 2D blocks
[m,n,~] = size(Iexp);
m = uint32(m);
n = uint32(n);
colWindow = uint32(colWindow);
rowWindow = uint32(rowWindow);
start_ind = reshape(bsxfun(@plus,[1:m-rowWindow+1]',[0:n-colWindow]*m),[],1); 
%Row indices
lin_row = permute(bsxfun(@plus,start_ind,[0:rowWindow-1])',[1 3 2]);  
%Get linear indices based on row and col indices 
indM = reshape(bsxfun(@plus,lin_row,(0:colWindow-1)*m),rowWindow*colWindow,[]);

%Get intensities of neighbouring voxels within expanded bounding box
nSlc = bboxDimV(6)-bboxDimV(5)+1;
nVox = size(indM,2);
neighbM = nan(nVox*nSlc,size(indM,1));
%loop over slices
for slcNum = 1:nSlc
    slice = Iexp(:,:,slcNum);
    neighbM((slcNum-1)*nVox+1:slcNum*nVox,:) = slice(indM).';
end

end


