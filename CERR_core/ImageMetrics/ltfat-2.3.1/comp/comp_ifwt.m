function f = comp_ifwt(c,g,a,J,Ls,ext)
%-*- texinfo -*-
%@deftypefn {Function} comp_ifwt
%@verbatim
%COMP_IFWT Compute Inverse DWT
%   Usage:  f = comp_ifwt(c,g,J,a,Ls,ext);
%
%   Input parameters:
%         c     : Cell array of length M = J*(filtNo-1)+1. Each element is Lc(m)*W array
%         g     : Synthesis wavelet filters - cell-array of length filtNo.
%         J     : Number of filterbank iterations.
%         a     : Upsampling factors - array of length filtNo.
%         Ls    : Length of the reconstructed signal.
%         ext   : 'per','zero','odd','even', Type of the forward transform boundary handling.
%
%   Output parameters:
%         f     : Reconstructed data - Ls*W array.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_ifwt.html}
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

% see comp_fwt for explanantion
assert(a(1)==a(2),'First two elements of a are not equal. Such wavelet filterbank is not suported.');


% Impulse responses to a correct format.
filtNo = numel(g);
%gCell = cellfun(@(gEl) conj(flipud(gEl.h(:))),g,'UniformOutput',0);
gCell = cellfun(@(gEl) gEl.h(:),g,'UniformOutput',0);

if strcmp(ext,'per')
   % Initial shift of the filter to compensate for it's delay.
   % "Zero" delay reconstruction is produced.
   % offset = cellfun(@(gEl) gEl.offset,g); 
   %offset = cellfun(@(gEl) 1-numel(gEl.h)-gEl.offset,g); 
   offset = cellfun(@(gEl) gEl.offset,g);
elseif strcmp(ext,'valid')
   offset = -cellfun(@(gEl) numel(gEl.h)-1,g);
else
   % -1 + 1 = 0 is used for better readability and to be consistent
   % with the shift in comp_fwt.
   % Here we are cheating, because we are making the filters
   % anti-causal to compensate for the delay introduced by causal
   % analysis filters. 
   % Instead, we could have used causal filters here and do the
   % delay compensation at the end (cropping f).
   % offset = -cellfun(@(gEl) numel(gEl),gCell) + (a -1) +1;
   offset = -(a-1);
end


Lc = cellfun(@(cEl) size(cEl,1),c);
Lc(end+1) = Ls;
tempca = c(1);
cRunPtr = 2;
for jj=1:J
   tempca=comp_ifilterbank_td([tempca;c(cRunPtr:cRunPtr+filtNo-2)],gCell,a,Lc(cRunPtr+filtNo-1),offset,ext); 
   cRunPtr = cRunPtr + filtNo -1;
end
% Save reconstructed data.
f = tempca;



% for ch=1:chans
%   tempca = c(LcStart(1):LcEnd(1),ch);
%   LcRunPtr = filtNo+1;
%   cRunPtr = 2;
%   for jj=1:J
%      tempca = comp_upconv({tempca}, Lc(LcRunPtr),{tmpg{1}},a(1),skip(1),ext,0);
%      for ff=2:filtNo
%         % tempca = tempca + comp_upconv({c{cRunPtr}(:,ch)}, Lc(LcRunPtr),{tmpg},a(ff),skip,doNoExt,0);
%         tempca = tempca + comp_upconv({c(LcStart(cRunPtr):LcEnd(cRunPtr),ch)}, Lc(LcRunPtr),{tmpg{ff}},a(ff),skip(ff),ext,0);
%         cRunPtr = cRunPtr + 1;
%      end
%      LcRunPtr = LcRunPtr + filtNo -1;
%   end
%   f(:,ch) = tempca;
% end


    
    

