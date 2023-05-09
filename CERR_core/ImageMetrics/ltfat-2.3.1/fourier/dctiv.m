function c=dctiv(f,L,dim)
%-*- texinfo -*-
%@deftypefn {Function} dctiv
%@verbatim
%DCTIV  Discrete Consine Transform type IV
%   Usage:  c=dctiv(f);
%
%   DCTIV(f) computes the discrete cosine transform of type IV of the
%   input signal f. If f is multi-dimensional, the transformation is
%   applied along the first non-singleton dimension.
%
%   DCTIV(f,L) zero-pads or truncates f to length L before doing the
%   transformation.
%
%   DCTIV(f,[],dim) or DCTIV(f,L,dim) applies the transformation along
%   dimension dim.
%
%   The transform is real (output is real if input is real) and
%   orthonormal.  It is its own inverse.
%
%   Let f be a signal of length L and let c=DCTIV(f). Then
%
%                          L-1
%     c(n+1) = sqrt(2/L) * sum f(m+1)*cos(pi*(n+.5)*(m+.5)/L) 
%                          m=0 
%
%   Examples:
%   ---------
%
%   The following figures show the first 4 basis functions of the DCTIV of
%   length 20:
%
%     % The dctiv is its own adjoint.
%     F=dctiv(eye(20));
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
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/dctiv.html}
%@seealso{dctii, dctiii, dstii}
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
%   REFERENCE: REF_DCTIV

complainif_argnonotinrange(nargin,1,3,mfilename);

if nargin<3
  dim=[];
end;

if nargin<2
  L=[];
end;

[f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,L,dim,'DCTIV');

if ~isempty(L)
  f=postpad(f,L);
end;
c = comp_dct(f,4);
% s1=zeros(2*L,W,assert_classname(f));
% c=zeros(L,W,assert_classname(f));
% 
% m1=1/sqrt(2)*exp(-(0:L-1)*pi*i/(2*L)).';
% m2=1/sqrt(2)*exp((1:L)*pi*i/(2*L)).';
% 
% for w=1:W
%   s1(:,w)=[m1.*f(:,w);flipud(m2).*f(L:-1:1,w)];
% end;
%   
% s1=exp(-pi*i/(4*L))*fft(s1)/sqrt(2*L);
% 
% % This could be done by a repmat instead.
% for w=1:W
%   c(:,w)=s1(1:L,w).*m1+s1(2*L:-1:L+1,w).*m2;
% end;
% 
% if isreal(f)
%   c=real(c);
% end;

c=assert_sigreshape_post(c,dim,permutedsize,order);

% This is a slow, but convenient way of expressing the algorithm.
%R=1/sqrt(2)*[diag(exp(-(0:L-1)*pi*i/(2*L)));...
%	     flipud(diag(exp((1:L)*pi*i/(2*L))))];
  
%c=exp(-pi*i/(4*L))*R.'*fft(R*f)/sqrt(2*L);

