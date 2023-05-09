function c=comp_filterbank(f,g,a);
%-*- texinfo -*-
%@deftypefn {Function} comp_filterbank
%@verbatim
%COMP_FILTERBANK  Compute filtering
%
%   Function groups filters in g according to a presence of .h and .H
%   fields. If .H is present, it is further decided whether it is a full
%   frequency response or a band-limited freq. resp.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_filterbank.html}
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

[L,W]=size(f);
M=numel(g);
c = cell(M,1);

% Divide filters into time domain and frequency domain groups
mFreq = 1:M;
mTime = mFreq(cellfun(@(gEl) isfield(gEl,'h') ,g)>0); 
mFreq(mTime) = [];

if ~isempty(mTime)
   % Pick imp. resp.
   gtime = cellfun(@(gEl) gEl.h, g(mTime),'UniformOutput',0);

   % Call the routine
   gskip = cellfun(@(gEl) gEl.offset ,g(mTime));
   c(mTime) = comp_filterbank_td(f,gtime,a(mTime),gskip,'per');
end

if ~isempty(mFreq)
   % Filtering in the frequency domain
   F=fft(f);
   % Pick frequency domain filters
   gfreq = g(mFreq);
   % Divide filters into the full-length and band-limited groups
   mFreqFullL = 1:numel(gfreq);
   amFreqCell = mat2cell(a(mFreq,:).',size(a,2),ones(1,numel(mFreq)));
   mFreqBL = mFreqFullL(cellfun(@(gEl,aEl) numel(gEl.H)~=L || (numel(aEl)>1 && aEl(2) ~=1), gfreq(:),amFreqCell(:))>0);
   mFreqFullL(mFreqBL) = [];
   
   mFreqFullL = mFreq(mFreqFullL);
   mFreqBL = mFreq(mFreqBL);
   
   if ~isempty(mFreqFullL)
      G = cellfun(@(gEl) gEl.H, g(mFreqFullL),'UniformOutput',0);
      c(mFreqFullL) = comp_filterbank_fft(F,G,a(mFreqFullL));
   end
   
   if ~isempty(mFreqBL)
      G = cellfun(@(gEl) gEl.H, g(mFreqBL),'UniformOutput',0);
      foff = cellfun(@(gEl) gEl.foff, g(mFreqBL));
      % Cast from logical to double.
      realonly = cellfun(@(gEl) cast(isfield(gEl,'realonly') && gEl.realonly,'double'), g(mFreqBL));
      c(mFreqBL) = comp_filterbank_fftbl(F,G,foff,a(mFreqBL,:),realonly);
   end
end







