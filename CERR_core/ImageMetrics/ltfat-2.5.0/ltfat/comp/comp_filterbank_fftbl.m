function c=comp_filterbank_fftbl(F,G,foff,a,realonly)
%COMP_FILTERBANK_FFTBL  Compute filtering in FD
%
%   does the same as comp_filterbank_fft, but for filters
%   with bandlimited frequency responses
%
%   Url: http://ltfat.github.io/doc/comp/comp_filterbank_fftbl.html

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

M = numel(G);
[L,W] = size(F);
c = cell(M,1);
if size(a,2)>1
   afrac=a(:,1)./a(:,2);
else
   afrac = a(:,1);
end

N = L./afrac;
assert(all(N-round(N)<1e-6),'%s: Bad output length. \n',upper(mfilename));
N = round(N);

fsuppRangeSmall = cellfun(@(fEl,GEl) mod([fEl:fEl+numel(GEl)-1].',L)+1 ,num2cell(foff),G,'UniformOutput',0);


for m=1:M
    c{m}=zeros(N(m),W,assert_classname(F,G{m}));

    for w=1:W
        Ftmp = F(fsuppRangeSmall{m},w).*G{m};
        postpadL = ceil(max([N(m),numel(G{m})])/N(m))*N(m);
        Ftmp = postpad(Ftmp,postpadL);
        
        Ftmp = sum(reshape(Ftmp,N(m),numel(Ftmp)/N(m)),2);
        
        Ftmp = circshift(Ftmp,foff(m));
        
        c{m}(:,w)=ifft(Ftmp)/afrac(m);
    end;
end


% Handle the real only as a separate filter using recursion
realonlyRange = 1:M;
realonlyRange = realonlyRange(realonly>0);

if ~isempty(realonlyRange)
   Gconj = cellfun(@(gEl) conj(gEl(end:-1:1)),G(realonlyRange),'UniformOutput',0);
   LG = cellfun(@(gEl) numel(gEl),Gconj);
   foffconj = -L+mod(L-foff(realonlyRange)-LG,L)+1;
   aconj = a(realonlyRange,:);

   cconj = comp_filterbank_fftbl(F,Gconj,foffconj,aconj,0);
   for ii=1:numel(cconj)
      c{realonlyRange(ii)} = (c{realonlyRange(ii)} + cconj{ii})/2;
   end
end

