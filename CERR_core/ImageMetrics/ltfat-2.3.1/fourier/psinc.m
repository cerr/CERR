function f=psinc(L,n)
%-*- texinfo -*-
%@deftypefn {Function} psinc
%@verbatim
%PSINC   Periodic Sinc function (Dirichlet function)
%   Usage:  f=psinc(L,n);
%
%   PSINC(L,n) computes the periodic Sinc function of length L with
%   n-1 local extrema. The DFT of the periodic Sinc function is the
%   periodic rectangle, PRECT, of length n.
%
%   Examples:
%   ---------
%
%   This figure displays a the periodic sinc function with 6 local extremas:
%
%     plot(psinc(30,7));
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/psinc.html}
%@seealso{prect}
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

complainif_argnonotinrange(nargin,2,2,mfilename);

if ~(numel(L)==1) || ~(isnumeric(L)) || mod(L,1)~=0 || L<=0
    error('%s: L has to be a positive integer.',upper(mfilename));
end;

if ~(numel(n)==1) || ~(isnumeric(L)) || mod(n,1)~=0 || n<=0
    error('%s: n has to be a positive integer.',upper(mfilename));
end;

x=(2*pi*(0:L-1)/L).';

n_odd = n-(1-mod(n,2));

f = sin(n_odd.*x./2)./(n_odd.*sin(x./2));

f(1)  = 1;

if (mod(n,2))==0;
    f = f+cos(x*n/2)/n_odd;
end;


