function c=zak(f,a);
%-*- texinfo -*-
%@deftypefn {Function} zak
%@verbatim
%ZAK  Zak transform
%   Usage:  c=zak(f,a);
%
%   ZAK(f,a) computes the Zak transform of f with parameter a.  The
%   coefficients are arranged in an a xL/a matrix, where L is the
%   length of f.
%
%   If f is a matrix then the transformation is applied to each column.
%   This is then indexed by the third dimension of the output.
%
%   Assume that c=zak(f,a), where f is a column vector of length L and
%   N=L/a. Then the following holds for m=0,...,a-1 and n=0,...,N-1
%
%                          N-1  
%     c(m+1,n+1)=1/sqrt(N)*sum f(m-k*a+1)*exp(2*pi*i*n*k/N)
%                          k=0
%
%   Examples:
%   ---------
%
%   This figure shows the absolute value of the Zak-transform of a Gaussian.
%   Notice that the Zak-transform is 0 in only a single point right in the
%   middle of the plot :
%
%     a=64;
%     L=a^2; 
%     g=pgauss(L);
%     zg=zak(g,a);
%
%     surf(abs(zg));
%   
%   This figure shows the absolute value of the Zak-transform of a 4th order
%   Hermite function.  Notice how the Zak transform of the Hermite functions
%   is zero on a circle centered on the corner :
%
%     a=64;
%     L=a^2; 
%     g=pherm(L,4);
%     zg=zak(g,a);
%
%     surf(abs(zg));
%
%
%   References:
%     A. J. E. M. Janssen. Duality and biorthogonality for discrete-time
%     Weyl-Heisenberg frames. Unclassified report, Philips Electronics,
%     002/94.
%     
%     H. Boelcskei and F. Hlawatsch. Discrete Zak transforms, polyphase
%     transforms, and applications. IEEE Trans. Signal Process.,
%     45(4):851--866, april 1997.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/zak.html}
%@seealso{izak}
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
%   TESTING: TEST_ZAK
%   REFERENCE: REF_ZAK

complainif_argnonotinrange(nargin,2,2,mfilename);

if (prod(size(a))~=1 || ~isnumeric(a))
  error([callfun,': a must be a scalar']);
end;

if rem(a,1)~=0
  error([callfun,': a must be an integer']);
end;


if size(f,2)>1 && size(f,1)==1
  % f was a row vector.
  f=f(:);
end;

L=size(f,1);
W=size(f,2);
N=L/a;

if rem(N,1)~=0
  error('The parameter for ZAK must divide the length of the signal.');
end;

c=zeros(a,N,W,assert_classname(f));

for ii=1:W
  % Compute it, it can be done in one line!
  % We use a normalized DFT, as this gives the correct normalization
  % of the Zak transform.
  c(:,:,ii)=dft(reshape(f(:,ii),a,N),[],2);
end;



