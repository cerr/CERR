function T = th_concavity(I,n);
% T =  th_concavity(I,n)
%
% Find a global threshold for a grayscale image by choosing the threshold to
% be in the shoulder of the histogram.
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
% A. Rosenfeld and P. De La Torre, "Histogram concavity analysis as an aid
% in threshold selection," IEEE Transactions on Systems, Man, and
% Cybernetics, vol. 13, pp. 231-235, 1983.
%
% P. K. Sahoo, S. Soltani, and A. K. C. Wong, "A survey of thresholding
% techniques," Computer Vision, Graphics, and Image Processing, vol. 41,
% pp. 233-260, 1988.
%
% Copyright (C) 2004 Antti Niemistö
% See README for more copyright information.

if nargin == 1
  n = 255;
end

I = double(I);

% Calculate the histogram and its convex hull.
h = hist(I(:),0:n);
H = hconvhull(h);

% Find the local maxima of the difference H-h.
lmax = flocmax(H-h);

% Find the histogram balance around each index.
for k = 0:n
  E(k+1) = hbalance(h,k);
end

% The threshold is the local maximum with highest balance.
E = E.*lmax;
[dummy ind] = max(E);
T = ind-1;
