function f=prect(L,n)
%-*- texinfo -*-
%@deftypefn {Function} prect
%@verbatim
%PRECT   Periodic rectangle
%   Usage:  f=prect(L,n);
%
%   psinc(L,n) computes the periodic rectangle (or square) function of
%   length L supported on n samples. The DFT of the periodic
%   rectangle function in the periodic sinc function, PSINC.
%
%    If n is odd, the output will be supported on exactly n samples
%     centered around the first sample.
%
%    If n is even, the output will be supported on exactly n+1 samples
%     centered around the first sample. The function value on the two
%     samples on the edge of the function will have half the magnitude of
%     the other samples.
%
%   Examples:
%   ---------
%
%   This figure displays an odd length periodic rectangle:
%
%     stem(prect(30,11));
%     ylim([-.2 1.2]);
%
%   This figure displays an even length periodic rectangle. Notice the
%   border points:
%
%     stem(prect(30,12));
%     ylim([-.2 1.2]);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/prect.html}
%@seealso{psinc}
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

f=pbspline(L,0,n);


