function c=dstii(f,L,dim)
%-*- texinfo -*-
%@deftypefn {Function} dstii
%@verbatim
%DSTII  Discrete Sine Transform type II
%   Usage:  c=dstii(f);
%           c=dstii(f,L);
%           c=dstii(f,[],dim);
%           c=dstii(f,L,dim);
%
%   DSTII(f) computes the discrete sine transform of type II of the
%   input signal f. If f is multi-dimensional, the transformation is
%   applied along the first non-singleton dimension.
%
%   DSTII(f,L) zero-pads or truncates f to length L before doing the
%   transformation.
%
%   DSTII(f,[],dim) or DSTII(f,L,dim) applies the transformation along
%   dimension dim.
%
%   The transform is real (output is real if input is real) and orthonormal.
%
%   The inverse transform of DSTII is DSTIII.
%
%   Let f be a signal of length L, let c=DSTII(f) and define the vector
%   w of length L by
%
%      w = [1 1 1 1 ... 1/sqrt(2)]
%
%   Then 
%
%                          L-1
%     c(n+1) = sqrt(2/L) * sum w(n+1)*f(m+1)*sin(pi*n*(m+.5)/L) 
%                          m=0 
%
%   Examples:
%   ---------
%
%   The following figures show the first 4 basis functions of the DSTII of
%   length 20:
%
%     % The dstiii is the adjoint of dstii.
%     F=dstiii(eye(20));
%
%     for ii=1:4
%       subplot(4,1,ii);
%       stem(F(:,ii));
%     end;
%
%
%   References:
%     K. Rao and P. Yip. Discrete Cosine Transform, Algorithms, Advantages,
%     Applications. Academic Press, 1990.
%     
%     M. V. Wickerhauser. Adapted wavelet analysis from theory to software.
%     Wellesley-Cambridge Press, Wellesley, MA, 1994.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/dstii.html}
%@seealso{dctii, dstiii, dstiv}
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
%   TESTING: TEST_PUREFREQ
%   REFERENCE: REF_DSTII

complainif_argnonotinrange(nargin,1,3,mfilename);

if nargin<3
  dim=[];
end;

if nargin<2
  L=[];
end;
   
[f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,L,dim,'DSTII');
 
if ~isempty(L)
  f=postpad(f,L);
end;

c = comp_dst(f,2);

c=assert_sigreshape_post(c,dim,permutedsize,order);

% This is a slow, but convenient way of expressing the above algorithm.
%R=1/sqrt(2)*[zeros(1,L); ...
%	     diag(exp((1:L)*pi*i/(2*L)));...	     
%	     [flipud(diag(-exp(-(1:L-1)*pi*i/(2*L)))),zeros(L-1,1)]];
%R(L+1,L)=i;

%c=i*(R'*fft([f;-flipud(f)])/sqrt(L)/2);


