function [f]=idwilt2(c,g1,p3,p4)
%-*- texinfo -*-
%@deftypefn {Function} idwilt2
%@verbatim
%IDWILT2  2D Inverse Discrete Wilson transform
%   Usage: f=idwilt2(c,g);
%          f=idwilt2(c,g1,g2);
%          f=idwilt2(c,g1,g2,Ls);
%
%   Input parameters:
%         c       : Array of coefficients.
%         g,g1,g2 : Window functions.
%         Ls      : Size of reconstructed signal.
%   Output parameters:
%         f       : Output data, matrix.
%
%   IDWILT2(c,g) calculates a separable two dimensional inverse
%   discrete Wilson transformation of the input coefficients c using the
%   window g. The number of channels is deduced from the size of the
%   coefficients c.
%
%   IDWILT2(c,g1,g2) does the same using the window g1 along the first
%   dimension, and window g2 along the second dimension.
%
%   IDWILT2(c,g1,g2,Ls) cuts the signal to size Ls after the transformation
%   is done.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/idwilt2.html}
%@seealso{dwilt2, dgt2, wildual}
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

%   AUTHOR : Peter L. Soendergaard

complainif_argnonotinrange(nargin,2,4,mfilename);

Ls=[];

switch nargin
  case 2
    g2=g1;
  case 3
    if prod(size(p3))>2
      % Two windows was specified.
      g2=p3;
    else
      g2=g1;
      Ls=p3;
    end;
  case 4
    g2=p3;
    Ls=p4;
end;
  

if ndims(c)<4 || ndims(c)>5
  error('c must be 4 or 5 dimensional.');
end;

M1=size(c,1)/2;
N1=size(c,2)*2;
M2=size(c,3)/2;
N2=size(c,4)*2;
W=size(c,5);

L1=M1*N1;
L2=M2*N2;

[g1,info]=wilwin(g1,M1,L1,'IDWILT2');
[g2,info]=wilwin(g2,M2,L2,'IDWILT2');

% If input is real, and window is real, output must be real as well.
inputwasreal = (isreal(g1) && isreal(g2) && isreal(c));


if isempty(Ls)
  Ls(1)=L1;
  Ls(2)=L2;
else
  Ls=bsxfun(@times,Ls,[1 1]);
end;

% --- first dimension

% Change c to correct shape.
c=reshape(c,2*M1,N1/2,L2*W);

c=comp_idwilt(c,g1);

c=postpad(c,Ls(1));

c=reshape(c,Ls(1),L2,W);

c=permute(c,[2,1,3]);

% --- second dimension

% Change c to correct shape.
c=reshape(c,2*M2,N2/2,Ls(1)*W);

c=comp_idwilt(c,g2);

c=postpad(c,Ls(2));

c=reshape(c,Ls(2),Ls(1),W);

f=permute(c,[2,1,3]);

% Clean signal if it is known to be real
if inputwasreal
  f=real(f);
end;


