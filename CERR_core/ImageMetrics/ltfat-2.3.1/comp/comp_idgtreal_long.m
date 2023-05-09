function f=comp_idgtreal_long(coef,g,L,a,M)
%-*- texinfo -*-
%@deftypefn {Function} comp_idgtreal_long
%@verbatim
%COMP_IDGTREAL_FAC  Full-window factorization of a Gabor matrix assuming.
%   Usage:  f=comp_idgtreal_long(c,g,L,a,M)
%
%   Input parameters:
%         c     : M x N x W array of coefficients.
%         g     : window (from facgabm).
%         a     : Length of time shift.
%         M     : Number of frequency shifts.
%   Output parameters:
%         f     : Reconstructed signal.
%
%   Do not call this function directly, use IDGT.
%   This function does not check input parameters!
%
%   If input is a matrix, the transformation is applied to
%   each column.
%
%   This function does not handle multidimensional data, take care before
%   you call it.
%
%   References:
%     T. Strohmer. Numerical algorithms for discrete Gabor expansions. In
%     H. G. Feichtinger and T. Strohmer, editors, Gabor Analysis and
%     Algorithms, chapter 8, pages 267--294. Birkhauser, Boston, 1998.
%     
%     P. L. Soendergaard. An efficient algorithm for the discrete Gabor
%     transform using full length windows. IEEE Signal Process. Letters,
%     submitted for publication, 2007.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_idgtreal_long.html}
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

%   AUTHOR : Peter L. Soendergaard.
%   TESTING: OK
%   REFERENCE: OK

% Get the factorization of the window.
gf = comp_wfac(g,a,M);      
        
% Call the computational subroutine.
f = comp_idgtreal_fac(coef,gf,L,a,M);




