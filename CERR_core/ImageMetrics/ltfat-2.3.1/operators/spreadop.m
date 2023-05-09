function h=spreadop(f,coef)
%-*- texinfo -*-
%@deftypefn {Function} spreadop
%@verbatim
%SPREADOP  Spreading operator
%   Usage: h=spreadop(f,c);
%
%   SPREADOP(f,c) applies the operator with spreading function c to the
%   input f. c must be square.
%
%   SPREADOP(f,c) computes the following for c of size L xL:
% 
%              L-1 L-1 
%     h(l+1) = sum sum c(m+1,n+1)*exp(2*pi*i*l*m/L)*f(l-n+1)
%              n=0 m=0
%
%   where l=0,...,L-1 and l-n is computed modulo L.
%
%   The combined symbol of two spreading operators can be found by using
%   tconv. Consider two symbols c1 and c2 and define f1 and f2 by:
%
%     h  = tconv(c1,c2)
%     f1 = spreadop(spreadop(f,c2),c1);
%     f2 = spreadop(f,h);
%
%   then f1 and f2 are equal.
%
%
%   References:
%     H. G. Feichtinger and W. Kozek. Operator quantization on LCA groups. In
%     H. G. Feichtinger and T. Strohmer, editors, Gabor Analysis and
%     Algorithms, chapter 7, pages 233--266. Birkhauser, Boston, 1998.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/operators/spreadop.html}
%@seealso{tconv, spreadfun, spreadinv, spreadadj}
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
%   TESTING: TEST_SPREAD
%   REFERENCE: REF_SPREADOP

complainif_argnonotinrange(nargin,2,2,mfilename);

if ndims(coef)>2 || size(coef,1)~=size(coef,2)
    error('Input symbol coef must be a square matrix.');
end;

L=size(coef,1);

% Change f to correct shape.
[f,Ls,W,wasrow,remembershape]=comp_sigreshape_pre(f,'DGT',0);

f=postpad(f,L);

h=zeros(L,W);

if issparse(coef) && nnz(coef)<L

    % The symbol is so sparse that the straighforward definition is
    % the fastest way to apply it.

    [mr,nr,cv]=find(coef);
    h=zeros(L,W);

    % We need mr and nr to be zero-indexed
    mr=mr-1;
    nr=nr-1;

    % This is the basic idea of the routine below
    %for ii=1:length(mr)
    %  for l=0:L-1
    %	h(l+1,:)=h(l+1,:)+cv(ii)*exp(-2*pi*i*l*mr(ii)/L)*f(mod(l-nr(ii),L)+1,:);
    %  end;
    %end;

    l=(-2*pi*i*(0:L-1)/L).';
    for ii=1:length(mr)
        bigmod=repmat(exp(l*mr(ii)),1,W);
        h=h+cv(ii)*(bigmod.*circshift(f,nr(ii)));
    end;

else

  % This version only touches coef one column at a time, and it suited
  % if coef is sparse.
  
  if issparse(coef)
    for n=0:L-1
      % The 'full' below is required for Matlab compatibility, as
      % Matlab refuses to do an ifft of a sparse matrix.
      cf=ifft(full(coef(:,n+1)))*L;
      modind=mod((0:L-1).'-n,L)+1;
      h=h+repmat(cf,1,W).*f(modind,:);
    end;            
  else
    for n=0:L-1
      cf=ifft(coef(:,n+1))*L;
      modind=mod((0:L-1).'-n,L)+1;
      h=h+repmat(cf,1,W).*f(modind,:);
    end;                            
  end;
  
end;


