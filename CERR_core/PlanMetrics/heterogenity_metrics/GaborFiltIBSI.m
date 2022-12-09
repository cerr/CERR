function [out3M,hGaborEven,hGaborOdd] = GaborFiltIBSI(scan3M,sigma,...
                                        lambda,gamma,theta,radius)
% out3M = GaborFiltIBSI(scan3M,sigma,lambda,gamma,theta);
%-----------------------------------------------------------------------
% INPUTS
% sigma  - Std. dev. of Gaussian envelope (no. voxels)
% lambda - Wavelength (no. voxels)
% gamma  - Spatial aspect ratio
% theta  - Orientation (degrees)
% radius - Kernel radius (no. voxels)
%-----------------------------------------------------------------------
% AI 02/07/2022

% Get filter scale along x, y axes
sigmaX = sigma;
sigmaY = sigma/gamma;

% Define filter size
d=4;
%if ~exist('radius','var')
%     if gamma > 1
%        radius = 1 + 2*floor(d*gamma*sigmaX+0.5);
%     else
%        radius = 1 + 2*floor(d*sigmaX+0.5);
%     end
%end
[X,Y] = meshgrid(-radius(2):radius(2),-radius(1):radius(1));

% Rotate grid to specified orientation
Xtheta = X .*cosd(theta) + Y .*sind(theta);
Ytheta = X .*sind(theta) - Y .*cosd(theta);

% Compute filter coefficients
hGaussian = exp( -1/2*( Xtheta.^2 ./ sigmaX^2 + Ytheta.^2 ./ sigmaY^2));
hGaborEven = hGaussian.*cos(2*pi.*Xtheta./lambda);
hGaborOdd  = hGaussian.*sin(2*pi.*Xtheta./lambda);
h = complex(hGaborEven,hGaborOdd);

% Apply slice-wise
out3M = nan(size(scan3M));
for nSlc = 1 :size(scan3M,3)
    scanM = scan3M(:,:,nSlc);
    outM = conv2(scanM,h,'same');
    %Return modulus
    out3M(:,:,nSlc) = abs(outM);
end


end