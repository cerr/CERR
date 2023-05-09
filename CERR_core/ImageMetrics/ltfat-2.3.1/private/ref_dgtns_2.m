function coef = ref_dgtns_2(f,g,V);
%-*- texinfo -*-
%@deftypefn {Function} ref_dgtns_2
%@verbatim
%REF_DGTNS_2  DGTNS by A.v.Leests Zak-transform method
%   Usage:  coef = ref_dgtns_2(f,g,V);
%
%   This function calculates the Gabor coefficients C_mk for a given 
%   signal phi and synthesis window w, on a lattice that is described by
%   the parameters A, p, q, J, and L (see calcg for a description of 
%   these parameters). The function gives only the non-zero elements.
%   (cf. C = reshape(phi*G',K,M) = Cmk.' with G=gabbas(w,xpo),
%   K = p*J, M = p*L*det(A) and Cmk the Gabor coefficients calculated
%   with this function
%
%   The method is based on the Zak transform.
%
%
%
%   Authors:
%   Marc Geilen, 1995.       (rectangular lattice)
%   Arno J. van Leest, 1998. (non-separable lattice)
%   Peter L. Soendergaard, 2006 (change of variable names)
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dgtns_2.html}
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

% Conversion of parameters.
phi=f;
w=g;

% V is on Peters  normal form.
a=V(1,1);
b=V(2,2);
Lpeter=size(g,1);
Mpeter=Lpeter/b;
Npeter=Lpeter/a;
c=gcd(a,Mpeter);
d=gcd(b,Npeter);
ppeter=a/c;
qpeter=Mpeter/c;

% Conversion, part 1 --------------------------
qarno=ppeter;
parno=qpeter;
J=c;

% ---------------------------------------------

% Convert to Arnos normal form

gcd1=gcd(V(1,1),V(1,2));
gcd2=gcd(V(2,1),V(2,2));

A=zeros(2);
A(1,:)=V(1,:)/gcd1;
A(2,:)=V(2,:)/gcd2;

[gg,h0,h1] = gcd(A(1,1),A(1,2));
D = det(A);

% Stupid, but needed in Octave
D=round(D);

% ---------- more conversion -------------
Larno=d/D;

% ---------------------------------------

x = A(2,:)*[h0;h1];
x = mod(x,D);
A = [1 0;x D];

%function [g,nrm]=calcg(A,p,q,J,L,w);

% Bereken de nodige variabelen.
%A = eqform(A);
swap = 0;
%D=det(A);
Marno=parno*Larno*D;
Narno=qarno*J;
K=parno*J;

r=-A(2,1);
h=gcd(D,qarno); 
f=D/h;

% Conversion, part 2 -----------

Narno=a;
K=Mpeter;
Marno=Npeter;

% ------------------------------

clear p
clear q
clear M
clear N
clear L
clear a
clear b
clear c
clear d

%function a = calca(A,p,q,J,L,w,phi);

%A = eqform(A);
%N = q*J;
%M = p*L*D;
%h = gcd(D,q);
%f = D/h;
%r = -A(2,1); 

w = reshape(w,Narno,Marno); 
phi = reshape(phi,f*parno*Narno,h*Larno);

% Bereken de zak-getransformeerde van phi en w.
phiz = fft(phi,[],2);
wz = fft(w,[],2);

% Bereken de matrix lmwz bestaande uit p 'quasi'-periodes van de 
% zakgetransformeerde van w(n). size(lmwz)=(p*N,M)
lmwz = zeros(f*parno*Narno,Marno);
O = (0:Marno-1)/Marno; O = O(ones([1 Narno]),:);
for n = 0:f*parno-1,
    lmwz(n*Narno+1:n*Narno+Narno,:) = wz.*exp(j*2*pi*n*O);
end

% Doe de nodige verschuivingen die nodig zijn voor non-separable lattices.
for i = 0:f*qarno-1, 
  lmwz(i*K+1:i*K+K,:) = circshift(lmwz(i*K+1:i*K+K,:),i*r*parno*Larno);
  phiz(i*K+1:i*K+K,:) = circshift(phiz(i*K+1:i*K+K,:),i*r*parno*Larno);
end;

% Bereken de fouriergetransformeerde van a_mk m.b.h. de vergelijking
% af(n,l)= som over s=<fq> K* zphi(n+sK,l;fpN) wz*(n+sK,l;N)
af = zeros(K,Marno);
for n = 0:K-1,
  for s = 0:f*parno-1,
     af(n+1,s*h*Larno+1:s*h*Larno+h*Larno)= ... 
              ... %K*diag(lmwz(n+1:K:f*parno*Narno,s*h*Larno+1:s*h*Larno+h*Larno)'*phiz(n+1:K:f*parno*Narno,:)).';
              K*sum(conj(lmwz(n+1:K:f*parno*Narno,s*h*Larno+1:s*h*Larno+h*Larno)).*phiz(n+1:K:f*parno*Narno,:));
  end;
end;

% Doe wat voorbereidingen om de array a te kunnen berekenen.
O1 = (0:parno*Larno-1)/Marno; O1 = O1(ones([1 K]),:);
O2 = (0:K-1).'/D/K; O2 = O2(:,ones([1 parno*Larno]));
af2 = zeros(D*K,parno*Larno);
for i = 0:D-1
 for v = 0:D-1,
    af2(i*K+1:i*K+K,:) = af2(i*K+1:i*K+K,:)+af(:,v*parno*Larno+1:v*parno*Larno+parno*Larno).*exp(j*2*pi*i*v/D);
 end;
 af2(i*K+1:i*K+K,:) = af2(i*K+1:i*K+K,:).*exp(j*2*pi*(i*O1+mod(i*r,-D)*O2));
end;

% Bereken de array a uit de fouriergetransformeerde af2
at = af2;
a = at;
for i = 0:D-1, 
 at(i*K+1:i*K+K,:) = fft(af2(i*K+1:i*K+K,:),[],1)/K;
 a(i*K+1:i*K+K,:) = ifft(at(i*K+1:i*K+K,:),[],2)/D;
end;
a = reshape(a,K,Marno);

coef=a(:);



