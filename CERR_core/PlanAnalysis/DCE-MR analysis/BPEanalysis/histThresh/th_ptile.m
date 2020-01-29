function T = th_ptile(I,p,n)
% T =  th_ptile(I,p,n)
%
% Find a global threshold for a grayscale image by using the p-tile method.
%
% In:
%  I    grayscale image
%  p    fraction of foreground pixels (defaults to 0.5)
%  n    maximum graylevel (defaults to 255)
%
% Out:
%  T    threshold
%
% References: 
%
% W. Doyle, "Operation useful for similarity-invariant pattern recognition,"
% Journal of the Association for Computing Machinery, vol. 9,pp. 259-267,
% 1962.
%
% C. A. Glasbey, "An analysis of histogram-based thresholding algorithms,"
% CVGIP: Graphical Models and Image Processing, vol. 55, pp. 532-537, 1993.
%
% Copyright (C) 2004 Antti Niemistö
% See README for more copyright information.

if nargin == 1
  p = 0.5;
  n = 255;
elseif nargin == 2
  n = 255;
end

I = double(I);

% Calculate the histogram.
y = hist(I(:),0:n);

% The threshold is chosen such that 50% of pixels lie in each category.
Avec = zeros(1,n+1);
for t = 0:n
  Avec(t+1) = A(y,t)/A(y,n);
end

[minimum,ind] = min(abs(Avec-p));
T = ind-1;
