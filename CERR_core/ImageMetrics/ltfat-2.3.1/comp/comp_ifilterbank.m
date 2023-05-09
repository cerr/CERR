function f = comp_ifilterbank(c,g,a,L)
%-*- texinfo -*-
%@deftypefn {Function} comp_ifilterbank
%@verbatim
%COMP_IFILTERBANK Compute inverse filterbank
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_ifilterbank.html}
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

M = numel(g);
classname = assert_classname(c{1});


% Divide filters into time domain and frequency domain groups
mFreq = 1:M;
mTime = mFreq(cellfun(@(gEl) isfield(gEl,'h') ,g)>0); 
mFreq(mTime) = [];

f = [];

if ~isempty(mTime)
   % Pick imp. resp.
   gtime = cellfun(@(gEl) gEl.h, g(mTime),'UniformOutput',0);

   % Call the routine
   gskip = cellfun(@(gEl) gEl.offset ,g(mTime));
   f = comp_ifilterbank_td(c(mTime),gtime,a(mTime),L,gskip,'per');
end

if ~isempty(mFreq)
   % Pick frequency domain filters
   gfreq = g(mFreq);
   % Divide filters into the full-length and band-limited groups
   mFreqFullL = 1:numel(gfreq);
   amFreqCell = mat2cell(a(mFreq,:).',size(a,2),ones(1,numel(mFreq)));
   mFreqBL = mFreqFullL(cellfun(@(gEl,aEl) numel(gEl.H)~=L || (numel(aEl)>1 && aEl(2) ~=1), gfreq(:),amFreqCell(:))>0);
   mFreqFullL(mFreqBL) = [];
   
   mFreqFullL = mFreq(mFreqFullL);
   mFreqBL = mFreq(mFreqBL);
   
   F = [];
   if ~isempty(mFreqBL)
      conjG = cellfun(@(gEl) cast(gEl.H,classname), g(mFreqBL),'UniformOutput',0);
      foff = cellfun(@(gEl) gEl.foff, g(mFreqBL));
      % Cast from logical to double.
      realonly = cellfun(@(gEl) cast(isfield(gEl,'realonly') && gEl.realonly,'double'), g(mFreqBL));
      F = comp_ifilterbank_fftbl(c(mFreqBL),conjG,foff,a(mFreqBL,:),realonly);
   end   
   
   if ~isempty(mFreqFullL)
      conjG = cellfun(@(gEl) cast(gEl.H,classname), g(mFreqFullL),'UniformOutput',0);
      
      % In case some of the filters were BL
      if isempty(F)
         F = comp_ifilterbank_fft(c(mFreqFullL),conjG,a(mFreqFullL));
      else
         F = F + comp_ifilterbank_fft(c(mFreqFullL),conjG,a(mFreqFullL));
      end
   end
   
   % In case some of the filters were TD
   if isempty(f)
      f = ifft(F);
   else
      f = f + ifft(F);
   end
end




% W = size(c{1},2);
% M = numel(g);
% classname = assert_classname(c{1});
% 
% f=zeros(L,W,classname);
% 
% % This routine must handle the following cases
% %
% %   * Time-side or frequency-side filters (test for  isfield(g,'H'))
% %
% %   * Cell array or matrix input (test for iscell(c))
% %
% %   * Regular or fractional subsampling (test for info.isfractional)
% 
% 
% for m=1:M
%     conjG=conj(comp_transferfunction(g{m},L));
%         
%     % For Octave 3.6 compatibility
%     conjG=cast(conjG,classname);
%     
%     % Handle fractional subsampling (this implies frequency side filters)
%     if isfield(g{m},'H') && numel(g{m}.H)~=L
%         N=size(c{m},1);
%         Llarge=ceil(L/N)*N;
%         amod=Llarge/N;
%         
%         for w=1:W                        
%             % This repmat cannot be replaced by bsxfun
%             innerstuff=middlepad(circshift(repmat(fft(c{m}(:,w)),amod,1),-g{m}.foff),L);
%             innerstuff(numel(g{m}.H)+1:end) = 0;
%             f(:,w)=f(:,w)+(circshift(innerstuff.*circshift(conjG,-g{m}.foff),g{m}.foff));
%         end;                
%     else
%         if iscell(c)
%             for w=1:W
%                 % This repmat cannot be replaced by bsxfun
%                 f(:,w)=f(:,w)+(repmat(fft(c{m}(:,w)),a(m),1).*conjG);
%             end;
%         else
%             for w=1:W
%                 % This repmat cannot be replaced by bsxfun
%                 f(:,w)=f(:,w)+(repmat(fft(c(:,m,w)),a(m),1).*conjG);
%             end;            
%         end;
%     end;
% end;
% 
% f = ifft(f);

