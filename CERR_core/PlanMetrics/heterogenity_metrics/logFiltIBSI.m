function out3M = logFiltIBSI(scan3M,sigmaV,cutOffV,pixelSizeV)
%-------------------------------------------------------------------------
% INPUTS:
% scan3M     : 3D input scan
% sigmaV     : Vector of Gaussian smoothing widths
%              [sigmaRows,sigmaCols,sigmaSl] in mm.
% PixelSizeV : Scan voxel sizes in mm.
% cutOffV    : Filter cutoff in mm. Filter size = 2.*cutOffV+1
%-------------------------------------------------------------------------
%AI 04/07/21

%Convert from physical to veoxel units
cutOffV = round(cutOffV./pixelSizeV(1:length(cutOffV)));
sigmaV = sigmaV./pixelSizeV(1:length(cutOffV));
filtSizV = floor(2.*cutOffV+1);

if length(sigmaV)==3 %3d filter
    
    %Calc. filter weights
    [X,Y,Z] = meshgrid(-cutOffV(2):cutOffV(2),-cutOffV(1):cutOffV(1),...
        -cutOffV(3):cutOffV(3));
    xsig2 = sigmaV(2)^2;
    ysig2 = sigmaV(1)^2;
    zsig2 = sigmaV(3)^2;
    h = exp(-(X.^2/(2*xsig2) + Y.^2/(2*ysig2) + Z.^2/(2*zsig2)));
    h(h<eps*max(h(:))) = 0;
    sumh = sum(h(:));
    if sumh ~= 0
        h  = h/sumh;
    end
    h1 = h.*(X.^2/xsig2^2 + Y.^2/ysig2^2 + Z.^2/zsig2^2 - 1/xsig2 -1/ysig2 -1/zsig2);
    h = h1 - sum(h1(:))/prod(filtSizV); %Shift to ensure sum result=0 on homogeneous regions
    %Apply LoG filter
    out3M = convn(scan3M,h,'same');
    
elseif length(sigmaV)==2 %2-d
    
    %Calc. filter weights
    [X,Y] = meshgrid(-cutOffV(2):cutOffV(2),-cutOffV(1):cutOffV(1));
    xsig2 = sigmaV(2)^2;
    ysig2 = sigmaV(1)^2;
    h = exp(-(X.^2/(2*xsig2) + Y.^2/(2*ysig2)));
    h(h<eps*max(h(:))) = 0;
    sumh = sum(h(:));
    if sumh ~= 0
        h  = h/sumh;
    end
    h1 = h.*(X.^2/xsig2^2 + Y.^2/ysig2^2- 1/xsig2 -1/ysig2);
    h = h1 - sum(h1(:))/prod(filtSizV); %Shift to ensure sum result=0 on homogeneous regions
    
    %Apply LoG filter
    out3M = nan(size(scan3M));
    for nSlc = 1:size(scan3M,3)
        out3M(:,:,nSlc) = conv2(scan3M(:,:,nSlc),h,'same');
    end
    
end

end