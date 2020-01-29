function T = th_minerror(I,n)
% T =  th_minerror(I,n)
%
% Find a global threshold for a grayscale image using the minimum error
% thresholding method.
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
% J. Kittler and J. Illingworth, "Minimum error thresholding," Pattern
% Recognition, vol. 19, pp. 41-47, 1986.
%
% C. A. Glasbey, "An analysis of histogram-based thresholding algorithms,"
% CVGIP: Graphical Models and Image Processing, vol. 55, pp. 532-537, 1993.
%
% Copyright (C) 2004 Antti Niemistö
% See README for more copyright information.

if nargin == 1
  n = 255;
end

I = double(I);

% Calculate the histogram.
y = hist(I(:),0:n);

warning off
% The threshold is chosen such that the following expression is minimized.
for j = 0:n
  mu = B(y,j)/A(y,j);
  nu = (B(y,n)-B(y,j))/(A(y,n)-A(y,j));
  p = A(y,j)/A(y,n);
  q = (A(y,n)-A(y,j)) / A(y,n);
  sigma2 = C(y,j)/A(y,j)-mu^2;
  tau2 = (C(y,n)-C(y,j)) / (A(y,n)-A(y,j)) - nu^2;
  vec(j+1) = p*log10(sqrt(sigma2)/p) + q*log10(sqrt(tau2)/q);
end
warning on

vec(vec==-inf) = NaN;
[minimum,ind] = min(vec);
T = ind-1;
