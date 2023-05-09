function [a,M,lt] = matrix2latticetype(L,V);
%-*- texinfo -*-
%@deftypefn {Function} matrix2latticetype
%@verbatim
%MATRIX2LATTICETYPE  Convert matrix form to standard lattice description
%   Usage: [a,M,lt] = matrix2latticetype(L,V);
%
%   [a,M,lt]=MATRIX2LATTICETYPE(L,V) converts a 2x2 integer matrix
%   description into the standard description of a lattice using the a,
%   M and lt. The conversion is only valid for the specified transform
%   length L.
%
%   The lattice type lt is a 1 x2 vector [lt_1,lt_2] denoting an
%   irreducible fraction lt_1/lt_2. This fraction describes the distance
%   in frequency (counted in frequency channels) that each coefficient is
%   offset when moving in time by the time-shift of a. Some examples:
%   lt=[0 1] defines a square lattice, lt=[1 2] defines the quinqux
%   (almost hexagonal) lattice, lt=[1 3] describes a lattice with a
%   1/3 frequency offset for each time shift and so forth.
%
%   An example:
%
%     [a,M,lt] = matrix2latticetype(120,[10 0; 5 10])
%
%   Coefficient layout:
%   -------------------
%
%   The following code generates plots which show the coefficient layout
%   and enumeration of the first 4 lattices in the time-frequecy plane:
%
%     a=6;
%     M=6;
%     L=36;
%     b=L/M;
%     N=L/a;
%     cw=3;
%     ftz=12;
%     
%     [x,y]=meshgrid(a*(0:N-1),b*(0:M-1));
%
%     lt1=[0 1 1 2];
%     lt2=[1 2 3 3];
%
%     for fignum=1:4
%       subplot(2,2,fignum);
%       z=y;
%       if lt2(fignum)>0
%         z=z+mod(lt1(fignum)*x/lt2(fignum),b);
%       end;
%       for ii=1:M*N
%         text(x(ii)-cw/4,z(ii),sprintf('%2.0i',ii),'Fontsize',ftz);
%         rectangle('Curvature',[1 1], 'Position',[x(ii)-cw/2,z(ii)-cw/2,cw,cw]);
%       end;
%       axis([-cw L -cw L]);
%       axis('square');
%       title(sprintf('lt=[%i %i]',lt1(fignum),lt2(fignum)),'Fontsize',ftz);
%     end;
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/matrix2latticetype.html}
%@seealso{latticetype2matrix}
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

% The Hermite normal form code was originally written by Arno J. van Leest, 1999.
% Positive determinant by Peter L. Soendergaard, 2004.
% Unique form by Christoph Wiesmeyr, 2012

if nargin~=2
  error('%s: Wrong number of input arguments.',upper(mfilename));
end;

% Check if matrix has correct size.
if size(V,1)~=2 || size(V,2)~=2
  error('%s: V must be a 2x2 matrix.',upper(mfilename));
end;

% Integer values
if norm(mod(V,1))~=0
  error('%s: V must have all integer values.',upper(mfilename));
end;

% Convert to Arnos normal form.
gcd1=gcd(V(1,1),V(1,2));
gcd2=gcd(V(2,1),V(2,2));

A=zeros(2);
A(1,:)=V(1,:)/gcd1;
A(2,:)=V(2,:)/gcd2;

D = det(A);

% Exchange vectors if determinant is negative.
if D<0
  D=-D;
  A=fliplr(A);
end;

[g,h0,h1] = gcd(A(1,1),A(1,2));

x = A(2,:)*[h0;h1];

x = mod(x,D);

% Octave does not automatically round the double division to integer
% numbers, and this causes confusion later in the GCD computations. 
a = gcd1;
b = round(D*gcd2);
s = round(x*gcd2);

% compute nabs format of <a,s>
b1 = gcd(s*lcm(a,L)/a,L);
[a,k1] = gcd(a,L);
s = k1*s;

% update b
b = gcd(b,gcd(b1,L));

% update s
s = mod(s,b);

% conversion from nabs to latticetype
M=L/b;

k=gcd(s,b);
lt=[s/k b/k];




