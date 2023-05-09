function L=noshearlength(Ls,a,M,lt)
%-*- texinfo -*-
%@deftypefn {Function} noshearlength
%@verbatim
%NOSHEARLENGTH  Transform length that does not require a frequency shear
%   Usage: L=noshearlength(Ls,a,M,lt)
%
%   NOSHEARLENGTH(Ls,a,M,lt) computes the next larger transform length
%   bigger or equal to Ls for which the shear algorithm does not require
%   a frequency side shear for a non-separable Gabor system specified by
%   a, M and lt. 
%
%   This property makes computation of the canonical dual and tight Gabor
%   windows GABDUAL and GABTIGHT and the DGT for a full length window
%   faster, if this transform length is choosen.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/noshearlength.html}
%@seealso{matrix2latticetype, dgt, gabdual, gabtight}
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

Lmin=dgtlength(1,a,M,lt);

if lt(1)==0
    Lsmallest=Lmin;
else
    c=gcd(a,M);
    
    % if lt(1)>0 then ks is everything in c which is relatively prime to
    % lt(2)
        
    kmax=c;
    while 1
        z=gcd(kmax,lt(2));
        if z==1
            break;
        end;
        kmax=kmax/z;
    end;

    Lsmallest=Lmin*c./kmax;

end;

L=ceil(Ls/Lsmallest)*Lsmallest;

