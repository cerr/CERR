function c=dcti(f,L,dim)
%-*- texinfo -*-
%@deftypefn {Function} dcti
%@verbatim
%DCTI  Discrete Cosine Transform type I
%   Usage:  c=dcti(f);
%           c=dcti(f,L);
%           c=dcti(f,[],dim);
%           c=dcti(f,L,dim);
%
%   DCTI(f) computes the discrete cosine transform of type I of the
%   input signal f. If f is a matrix then the transformation is applied to
%   each column. For N-D arrays, the transformation is applied to the first
%   non-singleton dimension.
%
%   DCTI(f,L) zero-pads or truncates f to length L before doing the
%   transformation.
%
%   DCTI(f,[],dim) or DCTI(f,L,dim) applies the transformation along
%   dimension dim.
%
%   The transform is real (output is real if input is real) and
%   it is orthonormal.
%
%   This transform is its own inverse.
%
%   Let f be a signal of length L, let c=dcti(f) and define the vector
%   w of length L by
%
%      w = [1/sqrt(2) 1 1 1 1 ...1/sqrt(2)]
%
%   Then
%
%                              L-1
%     c(n+1) = sqrt(2/(L-1)) * sum w(n+1)*w(m+1)*f(m+1)*cos(pi*n*m/(L-1))
%                              m=0
%
%   The implementation of this functions uses a simple algorithm that require
%   an FFT of length 2L-2, which might potentially be the product of a large
%   prime number. This may cause the function to sometimes execute slowly.
%   If guaranteed high speed is a concern, please consider using one of the
%   other DCT transforms.
%
%   Examples:
%   ---------
%
%   The following figures show the first 4 basis functions of the DCTI of
%   length 20:
%
%     % The dcti is its own adjoint.
%     F=dcti(eye(20));
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
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/dcti.html}
%@seealso{dctii, dctiv, dsti}
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
%   REFERENCE: REF_DCTI

complainif_argnonotinrange(nargin,1,3,mfilename);

if nargin<3
    dim=[];
end;

if nargin<2
    L=[];
end;

[f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,L,dim,'DCTI');

if ~isempty(L)
    f=postpad(f,L);
end;

if L==1
    c=f;
else
    c = comp_dct(f,1);
    %   c=zeros(L,W,assert_classname(f));
    %
    %   f2=[f;flipud(f(2:L-1,:))]/sqrt(2);
    %   f2(1,:)=f2(1,:)*sqrt(2);
    %   f2(L,:)=f2(L,:)*sqrt(2);
    %
    %   % Do DFT.
    %   s1=fft(f2)/sqrt(2*L-2);
    %
    %   % This could be done by a repmat instead.
    %   for w=1:W
    %     c(:,w)=s1(1:L,w)+[0;s1(2*L-2:-1:L+1,w);0];
    %   end;
    %
    %   c(2:L-1,:)=c(2:L-1,:)/sqrt(2);
    %
    %   if isreal(f)
    %     c=real(c);
    %   end;

end;

c=assert_sigreshape_post(c,dim,permutedsize,order);


