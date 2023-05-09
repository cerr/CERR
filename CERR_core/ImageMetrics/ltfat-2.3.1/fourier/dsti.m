function c=dsti(f,L,dim)
%-*- texinfo -*-
%@deftypefn {Function} dsti
%@verbatim
%DSTI  Discrete Sine Transform type I
%   Usage:  c=dsti(f);
%           c=dsti(f,L);
%           c=dsti(f,[],dim);
%           c=dsti(f,L,dim);
%
%   DSTI(f) computes the discrete sine transform of type I of the
%   input signal f. If f is multi-dimensional, the transformation is
%   applied along the first non-singleton dimension.
%
%   DSTI(f,L) zero-pads or truncates f to length L before doing the
%   transformation.
%
%   DSTI(f,[],dim) or DSTI(f,L,dim) applies the transformation along
%   dimension dim.
%
%   The transform is real (output is real if input is real) and orthonormal.
%
%   This transform is its own inverse.
%
%   Let f be a signal of length L and let c=DSTI(f). Then 
%
%                              L-1
%     c(n+1) = sqrt(2/(L+1)) * sum sin(pi*(n+1)*(m+1)/(L+1)) 
%                              m=0 
%   The implementation of this functions uses a simple algorithm that requires
%   an FFT of length 2N+2, which might potentially be the product of a large
%   prime number. This may cause the function to sometimes execute slowly.
%   If guaranteed high speed is a concern, please consider using one of the
%   other DST transforms.
%
%   Examples:
%   ---------
%
%   The following figures show the first 4 basis functions of the DSTI of
%   length 20:
%
%     % The dsti is its own adjoint.
%     F=dsti(eye(20));
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
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/dsti.html}
%@seealso{dcti, dstiii, dstiv}
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
%   REFERENCE: REF_DSTI

complainif_argnonotinrange(nargin,1,3,mfilename);

if nargin<3
  dim=[];
end;

if nargin<2
  L=[];
end;

[f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,L,dim,'DSTI');

if ~isempty(L)
  f=postpad(f,L);
end;

if L==1
  c=f;
 
else

  c = comp_dst(f,1);

end;

c=assert_sigreshape_post(c,dim,permutedsize,order);


