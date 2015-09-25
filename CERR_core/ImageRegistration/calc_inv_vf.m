function inv_vf = calc_inv_vf(vf_file_name,baseXv,baseYv,baseZv,movXv,movYv,movZv,interpFlag)
% function inv_vf = calc_inv_vf(vf_file_name,baseXv,baseYv,baseZv,movXv,movYv,movZv,interpFlag)
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
% interpFlag can be 'krig' or 'nearest'
%
% APA, 07/06/2012

% Get base and moving image sizes
sizeBase = [length(baseYv) length(baseXv) length(baseZv)];
sizeMov  = [length(movYv) length(movXv) length(movZv)];

% Read Vf from vf_file_name
if ischar(vf_file_name)
    [Vf4M,VfInfo] = readmha(vf_file_name);
else
    Vf4M = vf_file_name;
    clear vf_file_name
end

% Transform coordinate system from plastimatch to CERR
Xdeform = Vf4M(:,:,:,1);
Xdeform = flipdim(permute(Xdeform,[2,1,3]),3);
Ydeform = -Vf4M(:,:,:,2);
Ydeform = flipdim(permute(Ydeform,[2,1,3]),3);
Zdeform = -Vf4M(:,:,:,3);
Zdeform = flipdim(permute(Zdeform,[2,1,3]),3);

clear Vf4M;

% Get (x,y,z) coords of base scan
[Xb,Yb,Zb] = meshgrid(baseXv,baseYv,baseZv);
XBv = Xb(:);
clear Xb;
YBv = Yb(:);
clear Yb;
ZBv = Zb(:);
clear Zb;

% Calculate (x,y,z) coords of moving scan by adding vf to the base
XMv = XBv + Xdeform(:)/10;
clear XBv;
YMv = YBv + Ydeform(:)/10;
clear YBv;
ZMv = ZBv + Zdeform(:)/10;
clear ZBv;

% Clip values outside the scan field
XMv(XMv < min(movXv)) = min(movXv);
XMv(XMv > max(movXv)) = max(movXv);
YMv(YMv < min(movYv)) = min(movYv);
YMv(YMv > max(movYv)) = max(movYv);
ZMv(ZMv < min(movZv)) = min(movZv);
ZMv(ZMv > max(movZv)) = max(movZv);

% Convert (x,y,z) of moving scan to (r,c,s)
cV = interp1(movXv, 1:sizeMov(2), XMv, 'nearest');
clear XMv;
rV = interp1(movYv, 1:sizeMov(1), YMv, 'nearest');
clear YMv;
sV = interp1(movZv, 1:sizeMov(3), ZMv, 'nearest');
clear ZMv;

% Convert (r,c,s) to vectorized indices indV
indV = sub2ind(sizeMov,rV,cV,sV);
clear cV rV sV;

% Find indices that do not map
indNoMapV = ~ismember(1:prod(sizeMov),indV);

% Create inverse index mapping matrix
%invIndM = NaN*ones(sizeMov);
invIndM = zeros(sizeMov);
allIndV = 1:prod(sizeMov);
allNonMapV = ~ismember(allIndV,indV);
invIndM(indV) = 1:prod(sizeBase);
invIndErodeM = inf*ones(sizeMov);
invIndErodeM(indV) = 1:prod(sizeBase);


if strcmpi(interpFlag,'nearest')
    % Calculate inverse indices for points that did not map
    count = 0;
    nHood(:,:,1) = [0 0 0; 0 1 0; 0 0 0];
    nHood(:,:,2) = [0 1 0; 1 1 1; 0 1 0];   
    nHood(:,:,3) = [0 0 0; 0 1 0; 0 0 0];
    disp('filling in unmapped points...')
    while any(indNoMapV)
        count = count + 1;
        disp([num2str(count), '. ', num2str(length(find(indNoMapV==1))/prod(sizeMov)*100), '% filled.'])
        invIndTmpM = imdilate(invIndM,nHood);        
        invIndM(indNoMapV) = invIndTmpM(indNoMapV);        
        invIndTmpErodeM = imerode(invIndErodeM,nHood);    
        invIndErodeM(indNoMapV) = invIndTmpErodeM(indNoMapV);
        indNoMapV = invIndM(:) == 0;
    end
    
%     XdeformTmp = (Xdeform(invIndM) + Xdeform(invIndErodeM))/2;
%     YdeformTmp = (Ydeform(invIndM) + Ydeform(invIndErodeM))/2;
%     ZdeformTmp = (Zdeform(invIndM) + Zdeform(invIndErodeM))/2;
%     Xdeform(allNonMapV) = XdeformTmp(allNonMapV);
%     Ydeform(allNonMapV) = YdeformTmp(allNonMapV);
%     Zdeform(allNonMapV) = ZdeformTmp(allNonMapV);
    
    % Build the inverse vector field
    inv_vf(:,:,:,1) = -Xdeform(invIndM);
    inv_vf(:,:,:,2) = -Ydeform(invIndM);
    inv_vf(:,:,:,3) = -Zdeform(invIndM);
    
elseif strcmpi(interpFlag,'dummy')
    invIndM(indNoMapV) = 1;
    inv_vf(:,:,:,1) = -Xdeform(invIndM);
    inv_vf(:,:,:,2) = -Ydeform(invIndM);
    inv_vf(:,:,:,3) = -Zdeform(invIndM);
    
elseif strcmpi(interpFlag,'mean')
    % Inverse deformation matrices 
    XdeformInvM = zeros(sizeMov);
    YdeformInvM = zeros(sizeMov);
    ZdeformInvM = zeros(sizeMov);
    XdeformInvM(indV) = -Xdeform(invIndM(indV));    
    YdeformInvM(indV) = -Ydeform(invIndM(indV));
    ZdeformInvM(indV) = -Zdeform(invIndM(indV));
    mappedMaskM = invIndM > 0;
    
    % Calculate inverse indices for points that did not map
    count = 0;
    nHood(:,:,1) = [0 0 0; 0 1 0; 0 0 0];
    nHood(:,:,2) = [0 1 0; 1 1 1; 0 1 0];   
    nHood(:,:,3) = [0 0 0; 0 1 0; 0 0 0];
    disp('filling in unmapped points...')
    while ~all(mappedMaskM(:))
        count = count + 1;
        disp([num2str(count), '. ', num2str(length(find(mappedMaskM==0))/prod(sizeMov)*100), '% filled.'])
        mappedMaskM = convn(mappedMaskM,nHood,'same');        
        XdeformInvTmpM = convn(XdeformInvM,nHood,'same');
        YdeformInvTmpM = convn(YdeformInvM,nHood,'same');
        ZdeformInvTmpM = convn(ZdeformInvM,nHood,'same');
        XdeformInvM(allNonMapV) = XdeformInvTmpM(allNonMapV)./mappedMaskM(allNonMapV);
        YdeformInvM(allNonMapV) = YdeformInvTmpM(allNonMapV)./mappedMaskM(allNonMapV);
        ZdeformInvM(allNonMapV) = ZdeformInvTmpM(allNonMapV)./mappedMaskM(allNonMapV);
        indNanV = isnan(XdeformInvM);
        XdeformInvM(indNanV) = 0;
        YdeformInvM(indNanV) = 0;
        ZdeformInvM(indNanV) = 0;
        mappedMaskM = mappedMaskM > 0;        
    end
    
    % Build the inverse vector field
    inv_vf(:,:,:,1) = XdeformInvM;
    inv_vf(:,:,:,2) = YdeformInvM;
    inv_vf(:,:,:,3) = ZdeformInvM;
    
elseif strcmpi(interpFlag,'krig')
    
    inv_vf = zeros([sizeMov 3],'single');
    x_vf(isnan(invIndM),1) = NaN;
    x_vf(invIndM(indV),1) = -Xdeform(invIndM(indV));
    y_vf(isnan(invIndM),1) = NaN;
    y_vf(invIndM(indV),1) = -Ydeform(invIndM(indV));
    z_vf(isnan(invIndM),1) = NaN;
    z_vf(invIndM(indV),1) = -Zdeform(invIndM(indV));
    inv_vf(:,:,:,1) = reshape(x_vf,sizeMov);
    inv_vf(:,:,:,2) = reshape(y_vf,sizeMov);    
    inv_vf(:,:,:,3) = reshape(z_vf,sizeMov);
    inv_vf = fillMissingGrid(movXv,movYv,movZv, inv_vf);
    
end


