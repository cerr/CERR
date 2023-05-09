function [L,tfr]=dwiltlength(Ls,M);
%-*- texinfo -*-
%@deftypefn {Function} dwiltlength
%@verbatim
%DWILTLENGTH  DWILT/WMDCT length from signal
%   Usage: L=dwiltlength(Ls,M);
%
%   DWILTLENGTH(Ls,M) returns the length of a Wilson / WMDCT system with
%   M channels system is long enough to expand a signal of length
%   Ls. Please see the help on DWILT or WMDCT for an explanation of the
%   parameter M.
%
%   If the returned length is longer than the signal length, the signal will
%   be zero-padded by DWILT or WMDCT.
%
%   A valid transform length must be divisable by 2M. This
%   means that the minumal admissable transform length is :
%
%     Lsmallest = 2*M;
%
%   and all valid transform lengths are multipla of Lsmallest*
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/dwiltlength.html}
%@seealso{dwilt, wmdct}
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

if ~isnumeric(M) || ~isscalar(M)
  error('%s: M must be a scalar',upper(mfilename));
end;

if rem(M,1)~=0 || M<=0
  error('%s: M must be a positive integer',upper(mfilename));
end;

if ~isnumeric(Ls)
    error('%s: Ls must be numeric.',upper(mfilename));
end;

if ~isscalar(Ls)
    error('%s: Ls must a scalar.',upper(mfilename));
end;

Lsmallest=2*M;

L=ceil(Ls/Lsmallest)*Lsmallest;

b=L/(2*M);
tfr=M/b;



