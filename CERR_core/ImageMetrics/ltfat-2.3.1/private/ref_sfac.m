function [ff]=ref_sfac(f,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_sfac
%@verbatim
%REF_SFAC  Reference signal factorization
%   Usage: gf=ref_sfac(g,a,M);
%
%   Input parameters:
%         f     : Input signal.
%         a     : Length of time shift.
%         b     : Length of frequency shift.
%   Output parameters:
%         ff    : Factored signal
%
%  This function cannot handle multidimensional arrays.
%  Reshape to matrix BEFORE you call this.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_sfac.html}
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

% Calculate the parameters that was not specified
L=size(f,1);
W=size(f,2);

N=L/a;
b=L/M;

% The four factorization parameters.
[c,h_a,h_m]=gcd(a,M);
p=a/c;
q=M/c;
d=N/q;

permutation=zeros(q*b,1);

for k=0:p-1
  for s=0:d-1
    P(1+s+k*d)=s*p+k;
  end;
end;

P2=stridep(d,b)-1;

% Create permutation
for l=0:q-1
  for k=0:p-1
    for s=0:d-1     
      %permutation(l*b+s+k*d+1)=mod(P(s+k*d+1)*M-h_m*l*M+l*c,L)+1;
      %permutation(l*b+s*p+k+1)=mod(P2(s+k*d+1)*M-h_m*l*M+l*c,L)+1;
      permutation(l*p*d+s+k*d+1)=mod(s*c*p*q+(k-h_m*l)*c*q+l*c,L)+1;
    end;
  end;
end;

%ff=ref_fac(f,W,c,d,p,q,permutation);


fffull=zeros(p,q,d,c);

pr=reshape(permutation,d,p*q);

p2=zeros(p*q,d);
for l=0:q-1
  for k=0:p-1
    for s=0:d-1     
      %p2(l*p+k+1,s+1)=mod(s*c*p*q+(k-h_m*l)*c*q+l*c,L)+1;
      %p2(l*p+k+1,s+1)=mod(s*p*M+k*M-h_m*l*M+l*c,L)+1;
      p2(l*p+k+1,s+1)=mod(s*p*M+k*M+(c-h_m*M)*l,L)+1;
    end;
  end;
end;



% Output
ff=zeros(p*q,c*d);

% If d==1, it is not possible to further reduce the size of
% wk. Actually, some of the following code produces an
% error, because Matlab interprets an fft of a 1x q*p as a
% a row operation !
if d>1  
  
  % This loop iterates over the number of truly different wk's.
  for ko=0:c-1    
      
    % Execute the fft and place transposed in ff.    

    % The reshape done below is a dummy used to fix inconsistency in
    % octaves and matlabs handling of indices.
    wt=fft(reshape(f(p2+ko),p*q,d),[],2);
    
    for s=0:d-1
      ff(:,1+ko*d+s)=wt(:,s+1);
    end;

    for s=0:d-1
      fffull(:,:,s+1,ko+1)=reshape(wt(:,s+1),p,q,1,1);
    end;

  end;
    
else
    
  % Work arrays.
  work=zeros(p*q,1);
  
  for ko=0:c-1    
    % Permute input.
    work(:)=f(pr+ko,:);
    
    % Write the block.
    ff(:,ko+1)=work;
  end
  
end;

%norm(ff(:)-fffull(:))    



