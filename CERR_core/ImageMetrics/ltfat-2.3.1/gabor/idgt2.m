function [f]=idgt2(c,g1,p3,p4,p5)
%-*- texinfo -*-
%@deftypefn {Function} idgt2
%@verbatim
%IDGT2  2D Inverse discrete Gabor transform
%   Usage: f=idgt2(c,g,a);
%          f=idgt2(c,g1,g2,a);
%          f=idgt2(c,g1,g2,[a1 a2]);
%          f=idgt2(c,g,a,Ls);
%          f=idgt2(c,g1,g2,a,Ls);
%          f=idgt2(c,g1,g2,[a1 a2],Ls);
%
%   Input parameters:
%         c       : Array of coefficients.
%         g,g1,g2 : Window function(s).
%         a,a1,a2 : Length(s) of time shift.
%         Ls      : Length(s) of reconstructed signal (optional).
%
%   Output parameters:
%         f       : Output data, matrix.
%
%   IDGT2(c,g,a,M) will calculate a separable two dimensional inverse
%   discrete Gabor transformation of the input coefficients c using the
%   window g and parameters a, along each dimension. The number of channels
%   is deduced from the size of the coefficients c.
%
%   IDGT2(c,g1,g2,a) will do the same using the window g1 along the first
%   dimension, and window g2 along the second dimension.
%
%   IDGT2(c,g,a,Ls) or IDGT2(c,g1,g2,a,Ls) will cut the signal to size Ls*
%   after the transformation is done.
%
%   The parameters a and Ls can also be vectors of length 2.
%   In this case the first element will be used for the first dimension
%   and the second element will be used for the second dimension. 
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/idgt2.html}
%@seealso{dgt2, gabdual}
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

complainif_argnonotinrange(nargin,3,5,mfilename);

if ndims(c)<4 || ndims(c)>5
  error('c must be 4 or 5 dimensional.');
end;

doLs=0;

switch nargin
  case 3
    g2=g1;
    a=p3;
  case 4
    if prod(size(p3))>2
      % Two windows was specified.
      g2=p3;
      a=p4;
    else
      g2=g1;
      a=p3;
      Ls=p4;
      doLs=1;
    end;
  case 5
    g2=p3;
    a=p4;
    Ls=p5;
    doLs=1;
end;

if size(g1,2)>1
  if size(g1,1)>1
    error('g1 must be a vector');
  else
    % g1 was a row vector.
    g1=g1(:);
  end;
end;

if size(g2,2)>1
  if size(g2,1)>1
    error('g2 must be a vector');
  else
    % g2 was a row vector.
    g2=g2(:);
  end;
end;

if prod(size(a))>2 || prod(size(a))==0
  error('a must be a scalar or 1x2 vector');
end;

if length(a)==2
  a1=a(1);
  a2=a(2);
else
  a1=a;
  a2=a;
end;

Lwindow1=size(g1,1);
Lwindow2=size(g2,1);

M1=size(c,1);
N1=size(c,2);
M2=size(c,3);
N2=size(c,4);
W=size(c,5);

L1=a1*N1;
L2=a2*N2;

% Length of window must be dividable by M.
% We cannot automically zero-extend the window, as it can
% possible break some symmetry properties of the window, and we don't
% know which symmetries to preserve.
if rem(Lwindow1,M1)~=0
  error('Length of window no. 1 must be dividable by M1.')
end;

if rem(Lwindow2,M2)~=0
  error('Length of window no. 2 must be dividable by M2.')
end;
    


% --- first dimension

% Change c to correct shape.
c=reshape(c,M1,N1,M2*N2*W);

c=comp_idgt(c,g1,a1,[0 1],0,0);

% Check if Ls was specified.
if doLs
  c=postpad(c,Ls(1));
else
  Ls(1)=L1;
end;

% Change to correct size
c=reshape(c,Ls(1),M2*N2,W);

% Exchange first and second dimension.
c=permute(c,[2,1,3]);

% --- second dimension

% Change c to correct shape.
c=reshape(c,M2,N2,Ls(1)*W);

c=comp_idgt(c,g2,a2,[0 1],0,0);

% Check if Ls was specified.
if doLs
  c=postpad(c,Ls(2));
else
  Ls(2)=L2;
end;

% Change to correct size
c=reshape(c,Ls(2),Ls(1),W);

% Exchange first and second dimension.
f=permute(c,[2,1,3]);


