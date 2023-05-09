function [L,tfr]=dgtlength(Ls,a,M,varargin);
%-*- texinfo -*-
%@deftypefn {Function} dgtlength
%@verbatim
%DGTLENGTH  DGT length from signal
%   Usage: L=dgtlength(Ls,a,M);
%          L=dgtlength(Ls,a,M,lt);
%
%   DGTLENGTH(Ls,a,M) returns the length of a Gabor system that is long
%   enough to expand a signal of length Ls. Please see the help on
%   DGT for an explanation of the parameters a and M.
%
%   If the returned length is longer than the signal length, the signal
%   will be zero-padded by DGT.
%
%   A valid transform length must be divisable by both a and M. This
%   means that the minumal admissable transform length is :
%
%     Lsmallest = lcm(a,M);
%
%   and all valid transform lengths are multipla of Lsmallest*
%
%   Non-separable lattices:
%   -----------------------
%
%   DGTLENGTH(Ls,a,M,lt) does as above for a non-separable lattice with
%   lattice-type lt. For non-separable lattices, there is the additinal
%   requirement on the transform length, that the structure of the
%   lattice must be periodic. This gives a minimal transform length of :
%
%     Lsmallest = lcm(a,M)*lt(2);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/dgtlength.html}
%@seealso{dgt}
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

if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;

% This function takes some of the same input parameters as DGT. The phase
% parameter is ignore, because it does not change the length of the
% transform, but is included to not cause problem when dgtlength is
% called via framelength.
definput.keyvals.lt=[0 1];
definput.flags.phase={'freqinv','timeinv'};
[flags,kv,lt]=ltfatarghelper({'lt'},definput,varargin);

if ~isnumeric(M) || ~isscalar(M)
  error('%s: M must be a scalar',upper(mfilename));
end;

if ~isnumeric(a) || ~isscalar(a)
  error('%s: "a" must be a scalar',upper(mfilename));
end;

if rem(M,1)~=0 || M<=0
  error('%s: M must be a positive integer',upper(mfilename));
end;

if rem(a,1)~=0 || a<=0
  error('%s: "a" must be a positive integer',upper(mfilename));
end;

if ~isnumeric(Ls)
    error('%s: Ls must be numeric.',upper(mfilename));
end;

if ~isscalar(Ls)
    error('%s: Ls must a scalar.',upper(mfilename));
end;

if nargin<4

    Lsmallest=lcm(a,M);    

else

    if ~isnumeric(lt) || ~isvector(lt) || length(lt)~=2
        error('%s: lt must be a vector of length 2.',upper(mfilename));
    end;
    

    if (mod(lt(2),1)>0) || lt(2)<=0
        error('%s: lt(2) must be a positive integer.',upper(mfilename));
    end;
    
    if (mod(lt(1),1)>0) || lt(1)<0 || lt(1)>=lt(2)
        error(['%s: lt(1)=%i must be a positive integer that is larger than 0 but ' ...
               'smaller than lt(2)=%i.'],upper(mfilename),lt(1),lt(2));
    end;

    if lt(1)==0 && lt(2)~=1
        error('%s: The rectangular lattice can only be specified by lt=[0 1].',upper(mfilename));
    end;

    if gcd(lt(1),lt(2))>1
        error('%s: lt(1)/lt(2) must be an irriducible fraction.',upper(mfilename));
    end;

    Lsmallest=lcm(a,M)*lt(2);

end;

L=ceil(Ls/Lsmallest)*Lsmallest;



