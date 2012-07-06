function inv_vf = calc_inv_vf(vf_file_name,baseXv,baseYv,baseZv,movXv,movYv,movZv,planC)
% function inv_vf = calc_inv_vf(vf_file_name,baseXv,baseYv,baseZv,movXv,movYv,movZv,planC)
%
% This function calculates the inverse vector field.
%
% OUTPUT:
% The inverse vector field inv_vf has the dimensions of movScanNum.
% inv_vf's coordinate system is same as that of planC moving scanArray
% 
% INPUTS:
% vf_file_name refers to the file path/name for the .mha file containing
% the deformation vector field.
% baseXv,baseYv,baseZv are x,y,z vectors corresponding to the base scan grid
% movXv,movYv,movZv are x,y,z vectors corresponding to the moving scan grid
%
% APA, 07/06/2012

if ~exist('planC','var')
    global planC
end

% Get base and moving image sizes
sizeBase = [length(baseYv) length(baseXv) length(baseZv)];
sizeMov  = [length(movYv) length(movXv) length(movZv)];

% Read Vf from vf_file_name
[Vf4M,VfInfo] = readmha(vf_file_name);

% Transform coordinate system from plastimatch to CERR
Xdeform = Vf4M(:,:,:,1);
Xdeform = flipdim(permute(Xdeform,[2,1,3]),3);
Ydeform = Vf4M(:,:,:,2);
Ydeform = flipdim(permute(Ydeform,[2,1,3]),3);
Zdeform = Vf4M(:,:,:,3);
Zdeform = flipdim(permute(Zdeform,[2,1,3]),3);

% Get (x,y,z) coords of base scan
[Xb,Yb,Zb] = meshgrid(baseXv,baseYv,baseZv);
XBv = Xb(:);
YBv = Yb(:);
ZBv = Zb(:);

% Calculate (x,y,z) coords of moving scan by adding vf to the base
XMv = XBv + Xdeform(:)/10;
YMv = YBv + Ydeform(:)/10;
ZMv = ZBv + Zdeform(:)/10;

% Clip values outside the scan field
XMv(XMv < min(movXv)) = min(movXv);
XMv(XMv > max(movXv)) = max(movXv);
YMv(YMv < min(movYv)) = min(movYv);
YMv(YMv > max(movYv)) = max(movYv);
ZMv(ZMv < min(movZv)) = min(movZv);
ZMv(ZMv > max(movZv)) = max(movZv);

% Convert (x,y,z) of moving scan to (r,c,s)
cV = interp1(movXv, 1:sizeMov(2), XMv, 'nearest');
rV = interp1(movYv, 1:sizeMov(1), YMv, 'nearest');
sV = interp1(movZv, 1:sizeMov(3), ZMv, 'nearest');

% Convert (r,c,s) to vectorized indices indV
indV = sub2ind(sizeMov,rV,cV,sV);

% Find indices that do not map
indNoMapV = ~ismember(1:prod(sizeMov),indV);

% Create inverse index mapping matrix
invIndM = zeros(sizeMov);
invIndM(indV) = 1:prod(sizeBase);

% Calculate inverse indices for points that did not map
count = 0;
nHood(:,:,1) = [1 1 1; 1 1 1; 1 1 1];
nHood(:,:,2) = [1 1 1; 1 1 1; 1 1 1];
nHood(:,:,3) = [1 1 1; 1 1 1; 1 1 1];
disp('filling in unmapped points...')
while any(indNoMapV)
    count = count + 1;
    disp([num2str(count), '. ', num2str(length(find(indNoMapV==1))/prod(sizeBase)*100), '% filled.'])
    invIndTmpM = imdilate(invIndM,nHood);
    invIndM(indNoMapV) = invIndTmpM(indNoMapV);
    indNoMapV = invIndM(:) == 0;
end

% Build the inverse vector field
inv_vf(:,:,:,1) = -Xdeform(invIndM);
inv_vf(:,:,:,2) = -Ydeform(invIndM);
inv_vf(:,:,:,3) = -Zdeform(invIndM);

