function h=gabmul(f,c,p3,p4,p5)
%-*- texinfo -*-
%@deftypefn {Function} gabmul
%@verbatim
%GABMUL  Apply Gabor multiplier
%   Usage:  h=gabmul(f,c,a);
%           h=gabmul(f,c,g,a);
%           h=gabmul(f,c,ga,gs,a);
%
%   Input parameters:
%         f     : Input signal
%         c     : symbol of Gabor multiplier
%         g     : analysis/synthesis window
%         ga    : analysis window
%         gs    : synthesis window
%         a     : Length of time shift.
%   Output parameters:
%         h     : Output signal
%
%   GABMUL has been deprecated. Please use construct a frame multiplier
%   and use FRAMEMUL instead.
%
%   A call to GABMUL(f,c,ga,gs,a) can be replaced by :
%
%     [Fa,Fs]=framepair('dgt',ga,gs,a,M);
%     fout=framemul(f,Fa,Fs,s);
%
%   Original help:
%   --------------
%
%   GABMUL(f,c,g,a) filters f by a Gabor multiplier determined by
%   the symbol c over the rectangular time-frequency lattice determined by
%   a and M, where M is deduced from the size of c. The rows of c*
%   correspond to frequency, the columns to temporal sampling points.  The
%   window g will be used for both analysis and synthesis.
%
%   GABMUL(f,c,a) does the same using an optimally concentrated, tight
%   Gaussian as window function.
%
%   GABMUL(f,c,ga,gs,a) does the same using the window ga for analysis
%   and gs for synthesis.
%
%   The adjoint operator of GABMUL(f,c,ga,gs,a) is given by
%   GABMUL(f,conj(c),gs,ga,a).
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/deprecated/gabmul.html}
%@seealso{dgt, idgt, gabdual, gabtight}
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

warning(['LTFAT: GABMUL has been deprecated, please use FRAMEMUL ' ...
         'instead. See the help on GABMUL for more details.']);   

complainif_argnonotinrange(nargin,3,5,mfilename);

M=size(c,1);
N=size(c,2);

if nargin==3
  a=p3;
  L=a*N;
  ga=gabtight(a,M,L);
  gs=ga;
end;

if nargin==4;
  ga=p3;
  gs=p3;
  a=p4;
 end;

if nargin==5;  
  ga=p3;
  gs=p4;
  a=p5;
end;

if numel(c)==1
  error('Size of symbol is too small. You probably forgot to supply it.');
end;


assert_squarelat(a,M,'GABMUL',0);

% Change f to correct shape.
[f,Ls,W,wasrow,remembershape]=comp_sigreshape_pre(f,'DGT',0);

[coef,Ls]=dgt(f,ga,a,M);

if(~strcmp(class(c),'double'))
   coef = cast(coef,class(c));
end

for ii=1:W
  coef(:,:,ii)=coef(:,:,ii).*c;
end;


h=idgt(coef,gs,a,Ls);

% Change h to have same shape as f originally had.
h=comp_sigreshape_post(h,Ls,wasrow,remembershape);


