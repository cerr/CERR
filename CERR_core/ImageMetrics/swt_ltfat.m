function swc = swt_ltfat(x,w,J)
%  Input parameters:
%           x     : Vector or array. Applied to cols if the latter.
%           w     : Wavelet Filterbank.
%           J     : Number of filterbank iterations.
%
%     Output parameters:
%        swc: Output matrix SWC contains the vectors of coefficients
%             stored row-wise (similar to Matlab's swt):
%             for 1 <= i <= N, SWC(i,:) contains the detail
%             coefficients of level i and
%             SWC(N+1,:) contains the approximation coefficients of
%             level N.
%        ======= ONLY supports J=1 =========
%
% APA, 2/3/2023
% AI,  5/5/23   Extended to support 2-D arrays.


if isvector(x)
  inDim = length(x);
  swa = zeros(inDim,J);
  swd = zeros(inDim,J);
else
  inDim = size(x);
  swa = zeros(inDim(1),inDim(2),J);
  swd = zeros(inDim(1),inDim(2),J);
end

wl = fwtinit(w);
shift1 = abs(wl.g{1}.offset)+abs(wl.h{1}.offset);
shift2 = abs(wl.g{2}.offset)+abs(wl.h{2}.offset);

for i=1:J+1
  tmp = ufwt(x,w,J,'noscale');

  if length(inDim)== 1
    tmp = tmp.';
    swa(:,i) = circshift(circshift(flip(tmp(2,:),1), -(shift1)/2, 2), length(wl.g{1}.h)/2);
    swd(:,i) = circshift(circshift(flip(tmp(1,:),1), -(shift2)/2, 2), length(wl.g{1}.h)/2);
  else
    tmp = permute(tmp,[2 3 1]);
    swa(:,:,i) = circshift(circshift(flip(tmp(2,:,:),1), -(shift1)/2, 2), length(wl.g{1}.h)/2);
    swd(:,:,i) = circshift(circshift(flip(tmp(1,:,:),1), -(shift2)/2, 2), length(wl.g{1}.h)/2);
  end

  x = swa(:,i);
end

%For Matlab compatibility
contains = @(str, pattern) ~isempty(strfind(str, pattern));
if contains(w,'coif')
  swa = -swa;
end

if length(inDim)== 1
  swc = [swa(:,J),swd(:,J)].';
else
  swc = cat(3,swa(:,:,J),swd(:,:,J));
end

end
