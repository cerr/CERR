function b = bimodtest(y)
% b = bimodtest(y)
%
% Test if a histogram is bimodal.
%
% In:
%  y    histogram
%
% Out:
%  b    true if histogram is bimodal, false otherwise
%
% Copyright (C) 2004 Antti Niemistö
% See README for more copyright information.

len = length(y);
b = false;
modes = 0;

% Count the number of modes of the histogram in a loop. If the number
% exceeds 2, return with boolean return value false.
for k = 2:len-1
  if y(k-1) < y(k) & y(k+1) < y(k)
    modes = modes+1;
    if modes > 2
      return
    end
  end
end

% The number of modes could be less than two here
if modes == 2
  b = true;
end
