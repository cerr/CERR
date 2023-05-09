Lr=[24, 24, 24, 144,108,144,24,135,35,77,20];
ar=[ 4,  3,  6,   9,  9, 12, 6,  9, 5, 7, 1];
Mr=[ 6,  4,  4,  16, 12, 24, 8,  9, 7,11,20];

for ii=1:length(Lr);

  L=Lr(ii);
  
  M=Mr(ii);
  a=ar(ii);
  
  b=L/M;
  N=L/a;
  c=gcd(a,M);
  d=gcd(b,N);
  p=a/c;
  q=M/c;
  
  f=tester_crand(L,1);
  g=tester_crand(L,1);
  
  %gd=gabdual(g,a,M);
  
  cc  = ref_dgt(f,g,a,M);
  
  for jj=1:6
    
    cc_comp = feval(['ref_dgt_',num2str(jj)],f,g,a,M);
    
    cdiff=cc-cc_comp;

    res=norm(cdiff(:));      

    s=sprintf('REF%s L:%3i a:%3i b:%3i c:%3i d:%3i p:%3i q:%3i   %0.5g',num2str(jj),L, ...
             a,b,c,d,p,q,res);
    
    disp(s)
    
  end;
end;





%-*- texinfo -*-
%@deftypefn {Function} test_dgt_alg
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_dgt_alg.html}
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

