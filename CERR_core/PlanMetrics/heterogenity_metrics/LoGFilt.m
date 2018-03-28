function filtScan3M = LoGFilt(scan3M,kernelSize,sigma)
%Apply Laplacian of Gaussian filter 
% Ref: https://www.mathworks.com/help/images/ref/fspecial.html#f2-294801
%-------------------------------------------------------------------------
%AI 03/15/18


linV = -(kernelSize-1)/2:(kernelSize-1)/2;
[xM,yM] = meshgrid(linV,linV);
hg = exp(-(xM.^2 + yM.^2)/(2*(sigma^2)));
h = hg.*(xM.^2 + yM.^2-2*sigma^2)/(sigma^4 *sum(hg(:))); 
h0 = h - sum(h(:))/kernelSize^2; %Ensure sum of kernel elements
                                 %is zero so that convolution
                                 %on homogeneous regions returns zero


filtScan3M = convn(scan3M,h0,'same');  


end