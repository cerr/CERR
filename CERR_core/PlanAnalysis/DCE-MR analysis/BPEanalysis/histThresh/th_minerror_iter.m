function T = th_minerror_iter(I,n)
% T =  th_minerror_iter(I,n)
%
% Find a global threshold for a grayscale image using the iterative minimum
% error thresholding method.
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
% J. Kittler and J. Illingworth, "Minimum error thresholding," Pattern
% Recognition, vol. 19, pp. 41-47, 1986.
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

while T ~= Tprev
  
  % Calculate some statistics.
  mu = B(y,T)/A(y,T);
  nu = (B(y,n)-B(y,T))/(A(y,n)-A(y,T));
  p = A(y,T)/A(y,n);
  q = (A(y,n)-A(y,T)) / A(y,n);
  sigma2 = C(y,T)/A(y,T)-mu^2;
  tau2 = (C(y,n)-C(y,T)) / (A(y,n)-A(y,T)) - nu^2;

  % The terms of the quadratic equation to be solved.
  w0 = 1/sigma2-1/tau2;
  w1 = mu/sigma2-nu/tau2;
  w2 = mu^2/sigma2 - nu^2/tau2 + log10((sigma2*q^2)/(tau2*p^2));
  
  % If the next threshold would be imaginary, return with the current one.
  sqterm = w1^2-w0*w2;
  if sqterm < 0
    warning('MINERROR:NaN','Warning: th_minerror_iter did not converge.')
    return
  end

  % The updated threshold is the integer part of the solution of the
  % quadratic equation.
  Tprev = T;
  T = floor((w1+sqrt(sqterm))/w0);

  % If the threshold turns out to be NaN, return with the previous threshold.
  if isnan(T)
    warning('MINERROR:NaN','Warning: th_minerror_iter did not converge.')
    T = Tprev;
  end
  
end
