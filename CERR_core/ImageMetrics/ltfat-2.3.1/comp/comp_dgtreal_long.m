function cout=comp_dgtreal_long(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} comp_dgtreal_long
%@verbatim
%COMP_DGTREAL_LONG  Full-window factorization of a Gabor matrix.
%   Usage:  c=comp_dgtreal_long(f,g,a,M);
%
%   Input parameters:
%         f      : Factored input data
%         g      : Window
%         a      : Length of time shift.
%         M      : Number of channels.
%   Output parameters:
%         c      : M x N*W*R array of coefficients, where N=L/a
%
%   Do not call this function directly, use DGT instead.
%   This function does not check input parameters!
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
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_dgtreal_long.html}
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

%   AUTHOR    : Peter L. Soendergaard.
%   TESTING   : TEST_DGT
%   REFERENCE : OK 
  
L=size(f,1);
W=size(f,2);
N=L/a;
M2=floor(M/2)+1;
  
gf=comp_wfac(g,a,M);

% Compute the window application
% We know the output is real, but comp_dgt_walnut cannot detect this, so
% we force the output to be real.
cout=real(comp_dgt_walnut(f,gf,a,M));

% FFT with only positive frequencies
cout=fftreal(cout)/sqrt(M);
cout=reshape(cout,M2,N,W);



