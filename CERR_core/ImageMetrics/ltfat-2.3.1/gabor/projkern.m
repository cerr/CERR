function c=projkern(c,p2,p3,p4,p5);
%-*- texinfo -*-
%@deftypefn {Function} projkern
%@verbatim
%PROJKERN  Projection onto generating kernel space
%   Usage:  cout=projkern(cin,a);
%           cout=projkern(cin,g,a);
%           cout=projkern(cin,ga,gs,a);
%
%   Input parameters:
%         cin   : Input coefficients
%         g     : analysis/synthesis window
%         ga    : analysis window
%         gs    : synthesis window
%         a     : Length of time shift.
%   Output parameters:
%         cout  : Output coefficients
%
%   cout=PROJKERN(cin,a) projects a set of Gabor coefficients c onto the
%   space of possible Gabor coefficients. This means that cin and cout*
%   synthesize to the same signal. A tight window generated from a Gaussian
%   will be used for both analysis and synthesis.
%
%   The rationale for this function is a follows: Because the coefficient
%   space of a Gabor frame is larger than the signal space (since the frame
%   is redundant) then there are many coefficients that correspond to the
%   same signal.
%
%   Therefore, you might desire to work with the coefficients cin, but you
%   are in reality working with cout.
%
%   cout=PROJKERN(cin,g,a) does the same, using the window g for analysis
%   and synthesis.
%
%   cout=PROJKERN(cin,ga,gs,a) does the same, but for different analysis
%   ga and synthesis gs windows.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/projkern.html}
%@seealso{dgt, idgt}
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

complainif_argnonotinrange(nargin,2,4,mfilename);

M=size(c,1);
N=size(c,2);

if nargin==2
  a=p2;
  L=a*N;
  ga=gabtight(a,M,L);
  gs=ga;
end;

if nargin==3;
  ga=p2;
  gs=p2;
  a=p3;
  L=a*N;
end;

if nargin==4;  
  ga=p2;
  gs=p3;
  a=p4;
  L=a*N;
end;

assert_squarelat(a,M,1,'PROJKERN');

c=dgt(idgt(c,gs,a),ga,a,M);


