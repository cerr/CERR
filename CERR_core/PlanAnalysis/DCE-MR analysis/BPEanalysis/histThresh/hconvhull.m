function H = hconvhull(h)
% H = hconvhull(h)
%
% Find the convex hull of a histogram.
%
% In:
%  h    histogram
%
% Out:
%  H    convex hull of histogram
%
% References: 
%
% A. Rosenfeld and P. De La Torre, "Histogram concavity analysis as an aid
% in threhold selection," IEEE Transactions on Systems, Man, and
% Cybernetics, vol. 13, pp. 231-235, 1983.
%
% Copyright (C) 2004 Antti Niemistö
% See README for more copyright information.

len = length(h);
K(1) = 1;
k = 1;

% The vector K gives the locations of the vertices of the convex hull.
while K(k)~=len

  theta = zeros(1,len-K(k));
  for i = K(k)+1:len
    x = i-K(k);
    y = h(i)-h(K(k));
    theta(i-K(k)) = atan2(y,x);
  end

  maximum = max(theta);
  maxloc = find(theta==maximum);
  k = k+1;
  K(k) = maxloc(end)+K(k-1);
  
end

% Form the convex hull.
H = zeros(1,len);
for i = 2:length(K)
  H(K(i-1):K(i)) = h(K(i-1))+(h(K(i))-h(K(i-1)))/(K(i)-K(i-1))*(0:K(i)-K(i-1));
end
