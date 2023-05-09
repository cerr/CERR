function h=tconv(f,g)
%-*- texinfo -*-
%@deftypefn {Function} tconv
%@verbatim
%TCONV  Twisted convolution
%   Usage:  h=tconv(f,g);
%
%   TCONV(f,g) computes the twisted convolution of the square matrices
%   f and g.
%
%   Let h=TCONV(f,g) for f,g being L xL matrices. Then h is given by
%
%                   L-1 L-1
%      h(m+1,n+1) = sum sum f(k+1,l+1)*g(m-k+1,n-l+1)*exp(-2*pi*i*(m-k)*l/L);
%                   l=0 k=0
%
%   where m-k and n-l are computed modulo L.
%
%   If both f and g are of class sparse then h will also be a sparse
%   matrix. The number of non-zero elements of h is usually much larger than
%   the numbers for f and g. Unless f and g are very sparse, it can be
%   faster to convert them to full matrices before calling TCONV. 
%
%   The routine SPREADINV can be used to calculate an inverse convolution.
%   Define h and r by:
%
%     h=tconv(f,g);
%     r=tconv(spreadinv(f),h);
%
%   then r is equal to g.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/tconv.html}
%@seealso{spreadop, spreadfun, spreadinv}
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
%   REFERENCE: REF_TCONV

complainif_argnonotinrange(nargin,2,2,mfilename);

if any(size(f)~=size(g))
  error('Input matrices must be same size.');
end;

if size(f,1)~=size(f,2)
  error('Input matrices must be square.');
end;

L=size(f,1);

if issparse(f) && issparse(g)
  
  % Version for sparse matrices.
  
  % precompute the Lth roots of unity
  % Optimization note : the special properties and symmetries of the 
  % roots of unity could be exploited to reduce this computation.
  % Furthermore here we precompute every possible root if some are 
  % unneeded. 
  temp=exp((-i*2*pi/L)*(0:L-1)');
  [rowf,colf,valf]=find(f);
  [rowg,colg,valg]=find(g);
  
  h=sparse(L,L);  
  for indf=1:length(valf)
    for indg=1:length(valg)
      m=mod(rowf(indf)+rowg(indg)-2, L);
      n=mod(colf(indf)+colg(indg)-2, L);
      h(m+1,n+1)=h(m+1,n+1)+valf(indf)*valg(indg)*temp(mod((m-(rowf(indf)-1))*(colf(indf)-1),L)+1);
    end
  end

  
else

  % The conversion to 'full' is in order for Matlab to work.
  f=ifft(full(f))*L;
  g=ifft(full(g))*L;
  
  Tf=comp_col2diag(f);
  Tg=comp_col2diag(g);
  
  Th=Tf*Tg;
  
  h=spreadfun(Th);

end;

