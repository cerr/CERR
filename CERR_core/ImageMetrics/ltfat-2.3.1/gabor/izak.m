function f=izak(c);
%-*- texinfo -*-
%@deftypefn {Function} izak
%@verbatim
%IZAK  Inverse Zak transform
%   Usage:  f=izak(c);
%
%   IZAK(c) computes the inverse Zak transform of c. The parameter of
%   the Zak transform is deduced from the size of c.
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
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/izak.html}
%@seealso{zak}
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
%   REFERENCE: OK

complainif_argnonotinrange(nargin,1,1,mfilename);

a=size(c,1);
N=size(c,2);
W=size(c,3);

L=a*N;

% Create output matrix.
f=zeros(L,W,assert_classname(c));

for ii=1:W
  % Iterate through third dimension of c.
  % We use a normalized DFT, as this gives the correct normalization
  % of the Zak transform.
  f(:,ii)=reshape(idft(c(:,:,ii),[],2),L,1);
end;

