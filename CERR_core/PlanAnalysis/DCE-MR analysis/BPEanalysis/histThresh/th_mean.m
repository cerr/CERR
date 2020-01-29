function T = th_mean(I,n)
% T =  th_mean(I,n)
%
% Find a global threshold for a grayscale image by finding the mean of the
% pixels in the image.
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
% C. A. Glasbey, "An analysis of histogram-based thresholding algorithms,"
% CVGIP: Graphical Models and Image Processing, vol. 55, pp. 532-537, 1993.
%
% Copyright (C) 2004 Antti Niemistö
% See README for more copyright information.

if nargin == 1
  n = 255;
end

I = double(I);
T = floor(mean(I(:)));

% The implementation below uses the notations from the paper, but is
% significantly slower.

% Calculate the histogram.
%y = hist(I(:),0:n);

% The mean of the pixel values is chosen as the threshold.
%T = floor(B(y,n)/A(y,n));
