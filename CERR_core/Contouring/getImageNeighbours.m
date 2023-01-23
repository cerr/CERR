function neighbM = getImageNeighbours(scan3M,mask3M,rowWindow,colWindow,slcWindow)
% Returns intensities of neighbours of all voxels within a mask.
% Neighbourhood is defined by the rowWindow,colWindow,slcWindow inputs.
%-------------------------------------------------------------------------
% INPUTS
% scan3M        : Scan array
% mask3M        : 3D mask
% rowWindow     : No. rows defining neighbourhood around each voxel
% colWindow     : No. cols defining neighbourhood
% slcWindow     : No. slices defining neighbourhood (Optional. Default:1 for 2D neighbours)
%-------------------------------------------------------------------------
% AI 09/27/17
% AI 08/13/18 Extended to return 3D neighbours

%Pad the bounding box by [numRowsPad,numColsPad,numSlcPad]
numColsPad = floor(colWindow/2);
numRowsPad = floor(rowWindow/2);
if exist('slcWindow','var')
    numSlcPad = floor(slcWindow/2);
else
    slcWindow = 1;
    numSlcPad = 0;
end

if exist('padarray.m','file')
    Iexp = padarray(scan3M,[numRowsPad numColsPad numSlcPad],NaN,'both');
else
    Iexp = padarray_oct(scan3M,[numRowsPad numColsPad numSlcPad],NaN,'both');
end

%Get indices of 2D neighbours
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

%Get intensities of neighbouring voxels 
calcIndM = mask3M > 0;
neighbM = [];
nSlc = size(scan3M,3);
for slcNum = 1:nSlc %Loop over slices
    calcSlcIndV = calcIndM(:,:,slcNum);
    indSlcM = indM(:,calcSlcIndV);
    slcNumV = slcNum:slcNum+slcWindow-1; % Slices within the patch
    slNeighbM = [];
    for iSlc = 1:length(slcNumV)
        slc = slcNumV(iSlc);
        patch2M = Iexp(:,:,slc);
        slNeighbM = [slNeighbM;patch2M(indSlcM)];
    end
    neighbM = [neighbM,slNeighbM];
end





end


