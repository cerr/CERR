function [g,nlen] = pebfun(L,w,varargin)
%-*- texinfo -*-
%@deftypefn {Function} pebfun
%@verbatim
%PEBFUN Sampled, periodized EB-spline
%   Usage: g=pebfun(L,w)
%          g=pebfun(L,w,width)
%          [g,nlen]=pebfun(...)
%
%   Input parameters:
%         L      : Window length.
%         w      : Vector of weights of g*
%         width  : integer stretching factor, the support of g is width*length(w)
%
%   Output parameters:
%         g      : The periodized EB-spline.
%         nlen   : Number of non-zero elements in out.
%
%   PEBFUN(L,w) computes samples of a periodized EB-spline with weights 
%   w for a system of length L.
%
%   PEBFUN(L,w,width) additionally stretches the function by a factor of 
%   width.   
%
%   [g,nlen]=ptpfundual(...) as g might have a compact support,
%   nlen contains a number of non-zero elements in g. This is the case
%   when g is symmetric. If g is not symmetric, nlen is extended
%   to twice the length of the longer tail.
%
%   If nlen = L, g has a 'full' support meaning it is a periodization
%   of a EB spline function.
%
%   If nlen < L, additional zeros can be removed by calling
%   g=middlepad(g,nlen).
%
%
%   References:
%     K. Groechenig and J. Stoeckler. Gabor frames and totally positive
%     functions. Duke Math. J., 162(6):1003--1031, 2013.
%     
%     S. Bannert, K. Groechenig, and J. Stoeckler. Discretized Gabor frames of
%     totally positive functions. Information Theory, IEEE Transactions on,
%     60(1):159--169, 2014.
%     
%     T. Kloos and J. Stockler. Full length article: Zak transforms and gabor
%     frames of totally positive functions and exponential b-splines. J.
%     Approx. Theory, 184:209--237, Aug. 2014. [1]http ]
%     
%     T. Kloos. Gabor frames total-positiver funktionen endlicher ordnung.
%     Master's thesis, University of Dortmund, Dortmund, Germany, 2012.
%     
%     T. Kloos, J. Stockler, and K. Groechenig. Implementation of discretized
%     gabor frames and their duals. IEEE Transactions on Information Theory,
%     62(5):2759--2771, May 2016.
%     
%     References
%     
%     1. http://dx.doi.org/10.1016/j.jat.2014.05.010
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/pebfun.html}
%@seealso{dgt, pebfundual, gabdualnorm, normalize}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

%   AUTHORS: Joachim Stoeckler, Tobias Kloos  2012, 2016

complainif_notenoughargs(nargin,2,upper(mfilename));
complainif_notposint(L,'L',upper(mfilename))

if isempty(w) || ~isnumeric(w) || numel(w)<2
    error(['%s: w must be a nonempty numeric vector with at least',...
           ' 2 elements.'], upper(mfilename));
end

if any(w==0)
    error('%s: All weights w must be nonzero.', upper(mfilename));
end

%TODO: Sanity check for w e.g. 
% pebfun(1000,[1000,300]) is degenerate

%definput.import={'normalize'};
definput.keyvals.width=floor(sqrt(L));
[flags,~,width]=ltfatarghelper({'width'},definput,varargin);
complainif_notposint(width,'width',upper(mfilename));

w = sort(w);
n = length(w);
x = linspace(0,n-1/width,n*width);
x = x(:);
m = length(x);
x = repmat(x,1,n) + repmat([-n+1:0],m,1);
x = x(:)';
Y = zeros(n-1,length(x));

for k = 1:n-1
    if w(k) == w(k+1)
        Y(k,:) = x.*exp(w(k)*x).*(x>=0).*(x<=1) + ...
            (2-x).*exp(w(k)*x).*(x>1).*(x<=2);
    else
        Y(k,:) = (exp(w(k)*x)-exp(w(k+1)*x))/(w(k)-w(k+1)).*(x>=0).*(x<=1) + ...
            (exp(w(k)-w(k+1))*exp(w(k+1)*x)-exp(w(k+1)-w(k))*exp(w(k)*x))/(w(k)-w(k+1)).*(x>1).*(x<=2);
    end
end

for k = 2:n-1
    for j = 1:n-k
        if w(j) == w(j+k)
            Y(j,(k-1)*m+1:end) = x((k-1)*m+1:end)/k .* Y(j,(k-1)*m+1:end) + ...
                exp(w(j))*(k+1-x((k-1)*m+1:end))/k .* Y(j,(k-2)*m+1:end-m);
        else
            Y(j,(k-1)*m+1:end) = ( Y(j,(k-1)*m+1:end) - Y(j+1,(k-1)*m+1:end) + ...
                exp(w(j))*Y(j+1,(k-2)*m+1:end-m) - exp(w(j+k))*Y(j,(k-2)*m+1:end-m) )/ ...
                (w(j)-w(j+k));
        end
    end
end

if n == 1
    y = exp(w*x).*(x>=0).*(x<=1);
else
    y = Y(1,end-m+1:end);
end

if m <= L
    g = [y,zeros(1,L-m)]/sqrt(width);
else
    y = [y,zeros(1,ceil(m/L)*L-m)];
    g = sum(reshape(y,L,ceil(m/L)),2).'/sqrt(width);
end

nlen = min([L,m]);
g = g(:);
%g = normalize(g(:),flags.norm);

% Shift the window back
%[~,maxidx] = max(abs(g));
%g = circshift(g,-maxidx+1);

end




