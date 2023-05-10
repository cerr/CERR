function c = comp_chirpzt(f,K,deltao,o)


Ls = size(f,1);
W = size(f,2);

q = 1;
if 0
    %Use the decimation scheme
    % q fft of length
    q = ceil(Ls/K);
    Lfft = 2^nextpow2(2*K-1);
    
    fext = zeros(q*W,K);
    for w=0:W-1
       fext(1+w*q*K:w*q*K+Ls) = f(:,w+1);
    end
    f = fext.';
    Ls = K;
    k = (0:K-1).';
    
    W2 = exp(-1i*q*deltao*(k.^2)./2);
    
    preChirp = W2(1:K).*exp(-1i*k*q*o);
    postChirp = zeros(K,q);
    for jj=0:q-1
       postChirp(:,jj+1) = exp(-1i*jj*(k*deltao+o)).*W2(1:K);
    end
else
   %Reference: fft of the following length
   Lfft = nextfastfft(Ls+K-1);

   n = (0:max([Ls,K])-1).';
   W2 = exp(-1i*deltao*(n.^2)./2);

   preChirp = W2(1:Ls).*exp(-1i*o*(0:Ls-1).');
   postChirp = W2(1:K);
end


chirpFilt = zeros(Lfft,1);
chirpFilt(1:K) = conj(W2(1:K));
chirpFilt(end:-1:end-Ls+2) = conj(W2(2:Ls));
chirpFilt = fft(chirpFilt);

ff = bsxfun(@times,f,preChirp);
c = ifft(bsxfun(@times,fft(ff,Lfft),chirpFilt));



if q>1
   ctmp = c;
   c = zeros(K,W,assert_classname(f));
   for w=0:W-1
      c(:,w+1) = sum(ctmp(1:K,1+w*q:(w+1)*q).*postChirp,2);
   end
else
   c = bsxfun(@times,c(1:K,:),postChirp);
end
   
   
   
   
   
   

%
%   Url: http://ltfat.github.io/doc/comp/comp_chirpzt.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

