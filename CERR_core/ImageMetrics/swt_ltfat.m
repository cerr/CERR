function swc = swt_ltfat(x,w,J)
%  Input parameters:
%           x     : 1-d array
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

len = length(x);
swc = zeros(len,J+1);

swcTmpM = sqrt(2)*flip(ufwt(x,w,J),2);
for i=1:J+1
    swc(:,i) = circshift(swcTmpM(:,i),(-1)^(i+1));
end
swc = swc'; % for Matlab compatibility

