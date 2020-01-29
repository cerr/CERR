function x = A(y,j)
% x = A(y,j)
%
% The partial sum A from C. A. Glasbey, "An analysis of histogram-based
% thresholding algorithms," CVGIP: Graphical Models and Image Processing,
% vol. 55, pp. 532-537, 1993.
%
% In:
%  y    histogram
%  j    last index in the sum
%
% Out:
%  x    value of the sum
%  
%
% Copyright (C) 2004 Antti Niemistö
% See README for more copyright information.

x = sum(y(1:j+1));
