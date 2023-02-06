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

c = ufwt(img2D,w,J);
d = ufwt(squeeze(c(:,1,:))',w,J);
e = ufwt(squeeze(c(:,2,:))',w,J);

A = squeeze(d(:,1,:))'*2;
V = squeeze(d(:,2,:))'*2;
H = squeeze(e(:,1,:))'*2;
D = squeeze(e(:,2,:))'*2;

% Account for the differences in periodic boundary extension between
% Matlab and LTFAT

A = circshift(A,-1,1);
A = circshift(A,-1,2);

V = circshift(V,-1,1);
V = circshift(V,1,2);

D = circshift(D,1,1);
D = circshift(D,1,2);

H = circshift(H,1,1);
H = circshift(H,-1,2);

