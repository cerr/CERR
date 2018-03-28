function filtScan3M = filtImgGabor(scan3M,r, sig, lam, theta, omega)
% AI 03/22/18
% INPUTS
%  r       - final mask will be 2r+1 x 2r+1
%  sig     - standard deviation of Gaussian mask
%  lam     - elongation of Gaussian mask
%  theta   - orientation (in degrees)
%  omega   - [1] wavlength of underlying sine (sould be >=1)

hFilt = filterGabor2d( r, sig, lam, theta, omega, 0 );
filtScan3M = convn(scan3M,hFilt,'same');  

end