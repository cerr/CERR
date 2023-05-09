function gd=ref_gabdualns_2(g,V);
%-*- texinfo -*-
%@deftypefn {Function} ref_gabdualns_2
%@verbatim
%REF_GABDUALNS_2  GABDUALNS by A.v.Leest's Zak-transform method.
%   Usage:  g=ref_gabdualns_2(gamma,V);
%
%   This function calculates the dual window g of the given window
%   w for the Gabor expansion on a lattice that is described by the 
%   parameters A, p, q, J, and L. Furthermore, the l_2 norm of the 
%   difference of the (normalized) dual window and the (normalized) 
%   window is calculated. 
%
%   The method is based on the Zak transform.
%
%   Marc Geilen, 1995.           (rectangular lattice)
%   Arno J. van Leest, 1998.     (non-separable lattice)
%   Peter L. Soendergaard, 2006  (change of variable names)
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_gabdualns_2.html}
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


%  This documents Arno's variable names
%
%  D     the determinant of the matrix A and the number of time shifts
%        in each time segment (segment between two points on the
%        time-axis)
%  K=pJ  the number of samples in the freq. domain after each time shift.
%  N=qJ  the size of the time shift.
%  DN    length of a time segment.
%  p/q   the oversampling.
%  M=pLD the number of time shifts.
%  pL    the number of points on the time-axis.
%  MN    length of the signal.
%  MK    the number of lattice points (MK/MN=K/N=p/q is the oversampling).
%
%  (note that MN must be equal to the length of the window w).
%

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

g=reshape(g,Narno,Marno); 
wz = fft(g,[],2);

% gz zal de zakgetransformeerde van g bevatten
gz=zeros(Narno,Marno);
mgz=zeros(f*Narno,Marno);
mwz=zeros(f*Narno,Marno);

% The circshifts work along the rows!
O = (0:Marno-1);
O = O(ones([1 J]),:);
for n=0:qarno-1,
   i=rem(n*parno,qarno);
   k=fix(n*parno/qarno);
   for l=0:f-1,
    mwz((n+l*qarno)*J+1:(n+l*qarno)*J+J,:)= ...
      circshift(wz(i*J+1:i*J+J,:).*exp(j*2*pi*(k+parno*l)/Marno*O),...
	    [0 (n+l*qarno)*r*parno*Larno]);
   end;
end

for n=0:J-1,
   for l=0:Larno*h-1,  
        mgz(n+1:J:f*Narno,l+1:Larno*h:Marno)=...
	    f*parno/K*(pinv(mwz(n+1:J:f*Narno,l+1:Larno*h:Marno)))';    
   end;
end;

% Voer nu de omgekeerde bewerkingen uit van de verschuivingen en phase 
% correcties om gz te verkrijgen uit mgz
for n=0:qarno-1,
   i=rem(n*parno,qarno);
   k=fix(n*parno/qarno);
   gz(i*J+1:i*J+J,:)=circshift(mgz(n*J+1:n*J+J,:),[0 -n*r*parno*Larno]) ...
       .*exp(-j*2*pi*k/Marno*O);
end

% Bereken de functie g uit gz
gd = ifft(gz(1:Narno,:),[],2);
gd = gd(:);
if swap
  gd=parno/qarno*gd;
end;




