function T = th_intermeans_iter(I,n)
% T =  th_intermeans_iter(I,n)
%
% Find a global threshold for a grayscale image using the iterative
% intermeans method.
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
% T. Ridler and S. Calvard, "Picture thresholding using an iterative
% selection method," IEEE Transactions on Systems, Man, and Cybernetics,
% vol. 8, pp. 630-632, 1978.
%
% H. J. Trussell, "Comments on 'Picture thresholding using an iterative
% selection method'," IEEE Transactions on Systems, Man, and Cybernetics,
% vol. 9, p. 311, 1979.
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

% The initial estimate for the threshold is found with the MEAN algorithm.
T = th_mean(I,n);
Tprev = NaN;

% The threshold is found iteratively. In each iteration, the means of the
% pixels below (mu) the threshold and above (nu) it are found. The
% updated threshold is the mean of mu and nu.
while T ~= Tprev
  mu = B(y,T)/A(y,T);
  nu = (B(y,n)-B(y,T))/(A(y,n)-A(y,T));
  Tprev = T;
  T = floor((mu+nu)/2);
end
