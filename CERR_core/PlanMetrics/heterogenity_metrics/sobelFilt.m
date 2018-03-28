function [Gmag3M,Gdir3M] = sobelFilt(scan3M)
% Returns gradient computed using the 3 x 3 Sobel operator
% Ref. : Sobel, I. (1990). An isotropic 3× 3 image gradient operator. 
%        Machine vision for three-dimensional scenes, 376-379.
%--------------------------------------------------------------------------
% AI 03/14/18

%Sobel filter
Fx = [-1 0 1;-2 0 2;-1 0 1];
Fy = [1 2 1;0 0 0;-1 -2 -1];

Gx_3M = convn(scan3M,Fx,'same');  %Approximates horizontal gradient
Gy_3M = convn(scan3M,Fy,'same');  %Approximates vertical gradient

Gmag3M = sqrt(Gx_3M.^2+ Gy_3M.^2);
Gdir3M = atan(Gy_3M./Gx_3M);

end