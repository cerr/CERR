function y = flocmax(x)
% y = flocmax(x)
%
% Find the local maxima of a vector using a three point neighborhood.
%
% In:
%  x    vector
%
% Out:
%  y    binary vector with maxima of x marked as ones
%
% Copyright (C) 2004 Antti Niemistö
% See README for more copyright information.

len = length(x);
y = zeros(1,len);

for k = 2:len-1
  [dummy,ind] = max(x(k-1:k+1));
  if ind == 2
    y(k) = 1;
  end
end
