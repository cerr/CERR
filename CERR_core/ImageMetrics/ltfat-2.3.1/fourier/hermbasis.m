function [V,D]=hermbasis(L,p)
%-*- texinfo -*-
%@deftypefn {Function} hermbasis
%@verbatim
%HERMBASIS  Orthonormal basis of discrete Hermite functions
%   Usage:  V=hermbasis(L,p);
%           V=hermbasis(L);
%           [V,D]=hermbasis(...);
%
%   HERMBASIS(L,p) computes an orthonormal basis of discrete Hermite
%   functions of length L. The vectors are returned as columns in the
%   output. p is the order of approximation used to construct the
%   position and difference operator.
%
%   All the vectors in the output are eigenvectors of the discrete Fourier
%   transform, and resemble samplings of the continuous Hermite functions
%   to some degree (for low orders).
%
%   [V,D]=HERMBASIS(...) also returns the eigenvalues D of the Discrete
%   Fourier Transform corresponding to the Hermite functions.
%
%   Examples:
%   ---------
%
%   The following plot shows the spectrograms of 4 Hermite functions of
%   length 200 with order 1, 10, 100, and 190:
%
%     H=hermbasis(200);
%   
%     subplot(2,2,1);
%     sgram(H(:,1),'nf','tc','lin','nocolorbar'); axis('square');
%
%     subplot(2,2,2);
%     sgram(H(:,10),'nf','tc','lin','nocolorbar'); axis('square');
%    
%     subplot(2,2,3);
%     sgram(H(:,100),'nf','tc','lin','nocolorbar'); axis('square');
%    
%     subplot(2,2,4);
%     sgram(H(:,190),'nf','tc','lin','nocolorbar'); axis('square');
%
%
%   References:
%     A. Bultheel and S. Martinez. Computation of the Fractional Fourier
%     Transform. Appl. Comput. Harmon. Anal., 16(3):182--202, 2004.
%     
%     H. M. Ozaktas, Z. Zalevsky, and M. A. Kutay. The Fractional Fourier
%     Transform. John Wiley and Sons, 2001.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/hermbasis.html}
%@seealso{dft, pherm}
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

%   AUTHOR : Christoph Wiesmeyr, A. Bultheel 
%   TESTING: TEST_HERMBASIS
 
if nargin==1
    p=2;
end

% compute vector with values for side diagonals

d2 = [1 -2 1]; 
d_p = 1; 
s = 0; 
st = zeros(1,L);
for k = 1:p/2,
    d_p = conv(d2,d_p);
    st([L-k+1:L,1:k+1]) = d_p; st(1) = 0;
    temp = [1:k;1:k]; temp = temp(:)'./[1:2*k];
    s = s + (-1)^(k-1)*prod(temp)*2/k^2*st;       
end;

% build discrete Hamiltonian

P2=toeplitz(s);
X2=diag(real(fft(s)));
H =P2+X2; 

% Construct transformation matrix V (even and odd vectors)

r = floor(L/2);
even = ~rem(L,2);
T1 = (eye(L-1) + flipud(eye(L-1))) / sqrt(2);
T1(L-r:end,L-r:end) = -T1(L-r:end,L-r:end);
if (even), T1(r,r) = 1; end
T = eye(L); T(2:L,2:L) = T1;

% Compute eigenvectors of two banded matrices

THT = T*H*T';
E = zeros(L);
Ev = THT(1:r+1,1:r+1);
[ve,ee] = eig(Ev);
Od = THT(r+2:L,r+2:L);
[vo,eo] = eig(Od); 
%
% malab eig returns sorted eigenvalues
% if different routine gives unsorted eigvals, then sort first
%
% [d,inde] = sort(diag(ee));      [d,indo] = sort(diag(eo));
% ve = ve(:,inde');               vo = vo(:,indo');
%

V(1:r+1,1:r+1) = fliplr(ve);
V(r+2:L,r+2:L) = fliplr(vo);
V = T*V;

% shuffle eigenvectors

ind = [1:r+1;r+2:2*r+2]; 
ind = ind(:);
if (even)
    ind([L,L+2]) = [];
else 
    ind(L+1) = []; 
end

cor=2*floor(L/4)+1;
for k=(cor+1):2:(L-even)
    ind([k,k+1])=ind([k+1,k]);
end

V = V(:,ind');

if nargout>1
    % set up the eigenvalues
    k=0:L-1;
    D = exp(-1i*k*pi/2);
    D=D(:);
    
    % correction for even signal lengths
    if ~rem(L,2)
        D(end)=exp(-1i*L*pi/2);
    end

    % shuffle the eigenvalues in the right order
    even=~mod(L,2);
    cor=2*floor(L/4)+1;
    for k=(cor+1):2:(L-even)
        D([k,k+1])=D([k+1,k]);
    end

end;

