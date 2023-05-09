function coef=ref_dgtns_1(f,gamma,V)
%-*- texinfo -*-
%@deftypefn {Function} ref_dgtns_1
%@verbatim
%REF_DGT_1 Reference DGTNS using P.Prinz algorithm
%   Usage:  c=ref_dgtns_1(f,gamma,V);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dgtns_1.html}
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

a=V(1,1);
b=V(2,2);
r=-V(2,1);
L=size(gamma,1);
M=L/b;
N=L/a;
W=size(f,2);

c=gcd(a,M);
p=a/c;
q=M/c;
d=N/q;

if r==0
  % The grid is rectangular. Call another reference algorithm.
  coef=zeros(M*N,W);
  coef(:)=ref_dgt(f,gamma,a,M);

  return;
end;

% We can now assume that the grid is truly nonseperable,
% and so d>1.

% Conjugate.
gammac=conj(gamma);

% Level 2: Block diagonalize, and use that some blocks are
% the same up to permutations.

p1=stridep(M,L);
p2=stridep(N,M*N);

% Get shift offsets for stage 2 of the algorithm.
[mll,all]=shiftoffsets(a,M);
  
% Step 1: Permute
s1 = f(p1,:);

% Step 2: Multiply by DG'
s2=zeros(M*N,W);

% Do interpreter-language-optimized indexing.
[n_big,m_big]=meshgrid(0:N-1,0:b-1);
base=m_big*M-n_big*a+L;
base=base.';

% Work arrays.
work=zeros(b,M/c*W);
wk=zeros(N,b);
wkrect=zeros(N,b);

% Create fixed modulation matrix (Does not change with k)
fixedmod=zeros(N,b);
for n=0:N-1
  fixedmod(n+1,:)=exp(2*pi*i*r*n/L*(0:M:L-1));
end;
  
% This loop iterates over the number of truly different wk's.
for ko=0:c-1
    
  % Create the wk of the rectangular-grid case.
  wkrect(:)=gammac(mod(base+ko,L)+1);
  
  % Create wk of skewed case.
  wk=(fixedmod.*wkrect);

  
  % Setup work array.
  for l=0:M/c-1  
    k=ko+l*c;
    rowmod=exp(2*pi*i*r*(0:b-1)/b*all(l+1)).';

    work(:,l*W+1:(l+1)*W)=circshift(rowmod.*s1(1+(ko+l*c)*b:(ko+l*c+1)*b,:),-mll(l+1));
  end;

  % Do the actual multiplication,
  work2=wk*work;

  % Place the result correctly.
  for l=0:M/c-1
    k=ko+l*c;
    kmod=exp(2*pi*i*r*(0:N-1)*k/L).';
    colmod=exp(2*pi*i*r*(0:N-1)/b*mll(l+1)).';
    doublefac=exp(-2*pi*i*r/b*all(l+1)*mll(l+1));  


    s2(1+(ko+l*c)*N:(ko+l*c+1)*N,:)=doublefac*colmod.*kmod.*circshift(work2(:,l*W+1:(l+1)*W),all(l+1));
  end;

end;    

% Step 3: Permute again.
coef = s2(p2,:);

% Apply fft.
for n=1:N
  coef((n-1)*M+1:n*M,:)=fft(coef((n-1)*M+1:n*M,:));
end;



