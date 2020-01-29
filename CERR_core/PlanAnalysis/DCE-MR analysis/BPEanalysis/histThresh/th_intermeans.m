function T = th_intermeans(I,n);
% T =  th_intermeans(I,n)
%
% Find a global threshold for a grayscale image using the intermeans method
% commonly known as Otsu's method.
%
% In:
%  I    grayscale image
%  n    maximum graylevel (defaults to 255)
%
% Out:
%  T    threshold
%
% References: 
%
% N. Otsu, "A threshold selection method from gray-level histogram," IEEE
% Transactions on Systems, Man, and Cybernetics, vol. 9, pp. 62-66, 1979.
%
% C. A. Glasbey, "An analysis of histogram-based thresholding algorithms,"
% CVGIP: Graphical Models and Image Processing, vol. 55, pp. 532-537, 1993.
%
% Copyright (C) 2004 Antti Niemistö
% See README for more copyright information.

if nargin == 1
  n = 255;
end

% This algorithm is implemented in the Image Processing Toolbox.
%I = uint8(I);
%T = n*graythresh(I);

% The implementation below uses the notations from the paper, but is
% significantly slower.

I = double(I);

% Calculate the histogram.
y = hist(I(:),0:n);

warning off MATLAB:divideByZero
for j = 0:n
  mu = B(y,j)/A(y,j);
  nu = (B(y,n)-B(y,j))/(A(y,n)-A(y,j));
  vec(j+1) = A(y,j)*(A(y,n)-A(y,j))*(mu-nu)^2;
end
warning on MATLAB:divideByZero

[maximum,ind] = max(vec);
T = ind-1;
