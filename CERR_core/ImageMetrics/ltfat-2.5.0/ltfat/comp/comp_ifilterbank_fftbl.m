function F = comp_ifilterbank_fftbl(c,G,foff,a,realonly)
%COMP_IFILTERBANK_FFTBL  Compute filtering in FD
%
%   Url: http://ltfat.github.io/doc/comp/comp_ifilterbank_fftbl.html

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

%   called by comp_ifilterbank, performs frequency domain
%   filtering for filters with bandlimited frequency responses

M = numel(c);
W = size(c{1},2);

if size(a,2)>1
   afrac=a(:,1)./a(:,2);
else
   afrac = a(:,1);
end

N = cellfun(@(cEl) size(cEl,1),c);
if 0
   L = N.*afrac;
   assert(all(rem(L,1))<1e-6,'%s: Bad subband lengths. \n',upper(mfilename));
   L = round(L);
   assert(all(L==L(1)),'%s:Bad subband lengths. \n',upper(mfilename));
   L = L(1);
else
   L = round(afrac(1).*size(c{1},1));
end

F = zeros(L,W,assert_classname(c{1},G{1}));

fsuppRangeSmall = cellfun(@(fEl,GEl) mod([fEl:fEl+numel(GEl)-1].',L)+1,...
                          num2cell(foff),G,'UniformOutput',0);
%
for w=1:W 
   for m=1:M
     % Un-circshift
     Ctmp = circshift(fft(c{m}(:,w)),-foff(m));
     % Periodize and cut to the bandwidth of G{m}
     periods = ceil(numel(G{m})/N(m));
     Ctmp = postpad(repmat(Ctmp,periods,1),numel(G{m}));
     F(fsuppRangeSmall{m},w)=F(fsuppRangeSmall{m},w) + Ctmp.*conj(G{m});
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

   cconj = comp_ifilterbank_fftbl(F,Gconj,L,foffconj,aconj,0);
   for ii=1:numel(cconj)
      c{realonlyRange(ii)} = (c{realonlyRange(ii)} + cconj{ii})/2;
   end
end

