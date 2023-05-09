function [f,g]=iwmdct(c,g,Ls)
%-*- texinfo -*-
%@deftypefn {Function} iwmdct
%@verbatim
%IWMDCT  Inverse MDCT
%   Usage:  f=iwmdct(c,g);
%           f=iwmdct(c,g,Ls);
%
%   Input parameters:
%         c     : M*N array of coefficients.
%         g     : Window function.
%         Ls    : Final length of function (optional)
%   Output parameters:
%         f     : Input data
%
%   IWMDCT(c,g) computes an inverse windowed MDCT with window g. The
%   number of channels is deduced from the size of the coefficient array c.
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of WILWIN for more details.
%
%   IWMDCT(f,g,Ls) does the same, but cuts or zero-extends the final
%   result to length Ls.
%
%   [f,g]=IWMDCT(...) additionally outputs the window used in the
%   transform. This is usefull if the window was generated from a
%   description in a string or cell array.
%
%
%   References:
%     H. Boelcskei and F. Hlawatsch. Oversampled Wilson-type cosine modulated
%     filter banks with linear phase. In Asilomar Conf. on Signals, Systems,
%     and Computers, pages 998--1002, nov 1996.
%     
%     H. S. Malvar. Signal Processing with Lapped Transforms. Artech House
%     Publishers, 1992.
%     
%     J. P. Princen and A. B. Bradley. Analysis/synthesis filter bank design
%     based on time domain aliasing cancellation. IEEE Transactions on
%     Acoustics, Speech, and Signal Processing, ASSP-34(5):1153--1161, 1986.
%     
%     J. P. Princen, A. W. Johnson, and A. B. Bradley. Subband/transform
%     coding using filter bank designs based on time domain aliasing
%     cancellation. Proceedings - ICASSP, IEEE International Conference on
%     Acoustics, Speech and Signal Processing, pages 2161--2164, 1987.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/iwmdct.html}
%@seealso{wmdct, wilwin, dgt, wildual, wilorth}
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

%   AUTHOR: Peter L. Soendergaard
%   TESTING: TEST_WMDCT

complainif_argnonotinrange(nargin,2,3,mfilename);

wasrow=0;
if isnumeric(g)
  if size(g,2)>1
    if size(g,1)>1
      error('g must be a vector');
    else
      % g was a row vector.
      g=g(:);
      
      % If the input window is a row vector, and the dimension of c is
      % equal to two, the output signal will also
      % be a row vector.
      if ndims(c)==2
        wasrow=1;
      end;
    end;
  end;
end;

M=size(c,1);
N=size(c,2);
W=size(c,3);

a=M;
L=M*N;

assert_L(L,0,L,a,2*M,'IWMDCT');

g=wilwin(g,M,L,'IWMDCT');

f=comp_idwiltiii(c,g);

% Check if Ls was specified.
if nargin==3
  f=postpad(f,Ls);
else
  Ls=L;
end;

f=comp_sigreshape_post(f,Ls,wasrow,[0; W]);


