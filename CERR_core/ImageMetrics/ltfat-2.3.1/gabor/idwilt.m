function [f,g]=idwilt(c,g,Ls)
%-*- texinfo -*-
%@deftypefn {Function} idwilt
%@verbatim
%IDWILT  Inverse discrete Wilson transform
%   Usage:  f=idwilt(c,g);
%           f=idwilt(c,g,Ls);
%
%   Input parameters:
%      c     : 2M xN array of coefficients.
%      g     : Window function.
%      Ls    : Final length of function (optional)
%   Output parameters:
%      f     : Input data
%
%   IDWILT(c,g) computes an inverse discrete Wilson transform with window g.
%   The number of channels is deduced from the size of the coefficient array c.
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of WILWIN for more details.
%  
%   IDWILT(f,g,Ls) does the same, but cuts of zero-extend the final
%   result to length Ls.
%
%   [f,g]=IDWILT(...) additionally outputs the window used in the
%   transform. This is usefull if the window was generated from a
%   description in a string or cell array.
%
%
%   References:
%     H. Boelcskei, H. G. Feichtinger, K. Groechenig, and F. Hlawatsch.
%     Discrete-time Wilson expansions. In Proc. IEEE-SP 1996 Int. Sympos.
%     Time-Frequency Time-Scale Analysis, june 1996.
%     
%     Y.-P. Lin and P. Vaidyanathan. Linear phase cosine modulated maximally
%     decimated filter banks with perfectreconstruction. IEEE Trans. Signal
%     Process., 43(11):2525--2539, 1995.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/idwilt.html}
%@seealso{dwilt, wilwin, dgt, wilorth}
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
%   TESTING: TEST_DWILT
%   REFERENCE: OK

complainif_argnonotinrange(nargin,2,3,mfilename);

M=size(c,1)/2;
N=2*size(c,2);
W=size(c,3);

a=M;
L=M*N;

assert_L(L,0,L,a,2*M,'IDWILT');

[g,info]=wilwin(g,M,L,'IDWILT');

wasrow=0;
if (ndims(c)==2 && info.wasrow)
  wasrow=1;
end;

f=comp_idwilt(c,g);

% Check if Ls was specified.
if nargin==3
  f=postpad(f,Ls);
else
  Ls=L;
end;

f=comp_sigreshape_post(f,Ls,wasrow,[0; W]);


