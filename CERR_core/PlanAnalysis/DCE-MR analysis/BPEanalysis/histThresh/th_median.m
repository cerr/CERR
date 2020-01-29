function T = th_median(I,n)
% T =  th_median(I,n)
%
% Find a global threshold for a grayscale image by assuming that half of the
% pixels belong to the background and half to the foreground.
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
  n = 255;
end

T = th_ptile(I,.5,n);
