function E = hbalance(y,ind)
% E = hbalance(y,ind)
%
% Calculate the balance measure of the histogram around a histogram index.
%
% In:
%  y    histogram
%  ind  index about which balance is calculated
%
% Out:
%  E    balance measure
%
% References: 
%
% A. Rosenfeld and P. De La Torre, "Histogram concavity analysis as an aid
% in threhold selection," IEEE Transactions on Systems, Man, and
% Cybernetics, vol. 13, pp. 231-235, 1983.
%
% P. K. Sahoo, S. Soltani, and A. K. C. Wong, "A survey of thresholding
% techniques," Computer Vision, Graphics, and Image Processing, vol. 41,
% pp. 233-260, 1988.
%
% Copyright (C) 2004 Antti Niemistö
% See README for more copyright information.

n = length(y)-1;
E = A(y,ind)*(A(y,n)-A(y,ind));
