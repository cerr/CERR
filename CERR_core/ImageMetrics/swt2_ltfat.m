function [A,H,V,D] = swt2_ltfat(img2D,w,J)
%  Input parameters:
%           f     : Input data.
%           w     : Wavelet Filterbank.
%           J     : Number of filterbank iterations.
%
%     Output parameters:
%        [A,H,V,D]: decomposed coefficients similar to Matlab's swt2
%
% APA, 2/3/2023
% AI,  5/5/23   Fixed scaling to match Matlab

wl = fwtinit(w);
shiftH = abs(wl.g{1}.offset) + abs(wl.h{1}.offset);
shiftL = abs(wl.g{2}.offset) + abs(wl.h{2}.offset);
norm_length = length(wl.g{1}.h)/2;

sizeV = size(img2D);
swa = zeros(sizeV(1),sizeV(2),J);
swd = swa;
swh = swa;
swv = swa;

for i = 1:J

    % Apply along cols
    cols = ufwt(img2D,w,J,'noscale');

    % Apply along rows
    cols_L = squeeze(cols(:,1,:)).';
    cols_L = circshift(circshift(cols_L, -(shiftL)/2, 2), norm_length);

    cols_H = squeeze(cols(:,2,:)).';
    cols_H = circshift(circshift(cols_H, -(shiftH)/2, 2), norm_length);

    rows_L = ufwt(cols_L,w,J,'noscale');
    rows_H = ufwt(cols_H,w,J,'noscale');

    img_A = squeeze(rows_L(:,1,:)).';
    img_V = squeeze(rows_L(:,2,:)).';
    img_D = squeeze(rows_H(:,2,:)).';
    img_H = squeeze(rows_H(:,1,:)).';

    % Scaling for Matlab compatibility
    swa(:,:,i) = circshift(circshift(img_A, -(shiftL)/2, 2), norm_length);
    swd(:,:,i) = circshift(circshift(img_D, -(shiftH)/2, 2), norm_length);
    swh(:,:,i) = circshift(circshift(img_H, -(shiftL)/2, 2), norm_length);
    swv(:,:,i) = circshift(circshift(img_V, -(shiftH)/2, 2), norm_length);

    img2D = swa(:,:,i);

end

A = swa(:,:,J);
V = swv(:,:,J);
H = swh(:,:,J);
D = swd(:,:,J);

%For Matlab compatibility
contains = @(str, pattern) ~isempty(strfind(str, pattern));
if contains(w,'coif')
  V = -V;
  H = -H;
end


end