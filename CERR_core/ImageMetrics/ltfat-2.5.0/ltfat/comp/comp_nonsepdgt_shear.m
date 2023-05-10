function c=comp_nonsepdgt_shear(f,g,a,M,s0,s1,br);
%COMP_NONSEPDGT_SHEAR  Compute Non-separable Discrete Gabor transform
%   Usage:  c=nonsepdgt(f,g,a,M,lt);
%
%   This is a computational subroutine, do not call it directly.
%
%   Url: http://ltfat.github.io/doc/comp/comp_nonsepdgt_shear.html

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

%   AUTHOR : Nicki Holighaus and Peter L. Søndergaard
%   TESTING: TEST_NONSEPDGT
%   REFERENCE: REF_NONSEPDGT

% Assert correct input.

L=size(f,1);
W=size(f,2);
b=L/M;
N=L/a;

c=zeros(M,N,W,assert_classname(f,g));

ar = a*b/br;
Mr = L/br;
Nr = L/ar;

            
if s1 ~= 0
    p = comp_pchirp(L,s1);
    g = p.*g;
    f = bsxfun(@times,p,f);
end

if s0 == 0

    c_rect = comp_dgt_long(f,g,a,M);
    tmp1=mod(s1*a*(L+1),2*N);

    for k=0:Nr-1   
        phsidx= mod(mod(tmp1*k,2*N)*k,2*N);
        phs = exp(pi*1i*phsidx/N);
        idx2 = floor(mod(-s1*k*a+(0:Mr-1)*b,L)/b);
            
        c(idx2+1,k+1,:) = c_rect(:,k+1,:).*phs;
    end;
    
else 
    twoN=2*N;
    cc1=ar/a;
    cc2=mod(-s0*br/a,twoN);
    cc3=mod(a*s1*(L+1),twoN);
    cc4=mod(cc2*br*(L+1),twoN);
    cc5=mod(2*cc1*br,twoN);
    cc6=mod((s0*s1+1)*br,L);
    
    p = comp_pchirp(L,-s0);
    g = p.*fft(g)/L;
    f = bsxfun(@times,p,fft(f));
    
    c_rect = comp_dgt_long(f,g,br,Nr);
    
    for k=0:Nr-1   
        for m=0:Mr-1
            sq1=mod(k*cc1+cc2*m,twoN);
            phsidx = mod(mod(cc3*sq1.^2,twoN)-mod(m*(cc4*m+k*cc5),twoN),twoN);            
            phs = exp(pi*1i*phsidx/N);
            
            idx1 =       mod(   cc1*k+cc2*m,N);
            idx2 = floor(mod(-s1*ar*k+cc6*m,L)/b);
            
            c(idx2+1,idx1+1,:) = c_rect(mod(-k,Nr)+1,m+1,:).*phs;
        end;
    end;                    
end;


% This is some old code just kept around for historical/documentational
% purposes
if 0

    ind = [ar 0; 0 br]*[kron((0:L/ar-1),ones(1,L/br));kron(ones(1,L/ar), ...
                                                  (0:L/br-1))];

   
    phs = reshape(mod((s1*(ind(1,:)-s0*ind(2,:)).^2+s0*ind(2,:).^2)*(L+1) ...
                      -2*(s0 ~= 0)*ind(1,:).*ind(2,:),2*L),Mr,Nr);

    ind_final = [1 0;-s1 1]*[1 -s0;0 1]*ind;

    phs = exp(pi*1i*phs/L);

    ind_final = mod(ind_final,L);
    
    if s1 ~= 0
        g = comp_pchirp(L,s1).*g;
        f = bsxfun(@times,comp_pchirp(L,s1),f);
    end
    
    if s0 ~= 0
        g = comp_pchirp(L,-s0).*fft(g)/L;
        f = bsxfun(@times,comp_pchirp(L,-s0),fft(f));
        
        c_rect = comp_dgt_long(f,g,br,Nr);
        
        for w=0:W-1
            
            c(floor(ind_final(2,:)/b)+1+(ind_final(1,:)/a)*M+w*M*N) = ...
                c_rect(ind(1,[1:Mr,end:-1:Mr+1])/ar+1+(ind(2,:)/br)*Nr+w*M*N).* ...
                phs(ind(2,:)/br+1+(ind(1,:)/ar)*Mr);
        end;
    else 
        
        c_rect = comp_dgt_long(f,g,ar,Mr);
        
        for w=1:W
            c_rect(:,:,w) = phs.*c_rect(:,:,w);
        end;
        
        % The code line below this comment executes the commented for-loop
        % using Fortran indexing.
        %
        % for jj = 1:size(ind,2)        
        %     c(floor(ind_final(2,jj)/b)+1, ind_final(1,jj)/a+1) = ...
        %         c_rect(ind(2,jj)/br+1, ind(1,jj)/ar+1);
        % end
        for w=0:W-1
            c(floor(ind_final(2,:)/b)+1+(ind_final(1,:)/a)*M+w*M*N) = ... 
                c_rect(ind(2,:)/br+1+(ind(1,:)/ar)*Mr+w*M*N);
        end;
    end;
        
end;



