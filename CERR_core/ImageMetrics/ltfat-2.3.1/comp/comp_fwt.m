function c = comp_fwt(f,h,a,J,ext)
%-*- texinfo -*-
%@deftypefn {Function} comp_fwt
%@verbatim
%COMP_FWT Compute DWT using FWT
%   Usage:  c=comp_fwt(f,h,J,a,Lc,ext);
%
%   Input parameters:
%         f     : Input data - L*W array.
%         h     : Analysis Wavelet filters - cell-array of length filtNo.
%         J     : Number of filterbank iterations.
%         a     : Subsampling factors - array of length filtNo. 
%         ext   : 'per','zero','even','odd' Type of the forward transform boundary handling.
%
%   Output parameters:
%         c     : Cell array of length M. Each element is Lc(m)*W array.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_fwt.html}
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

% This could be removed with some effort. The question is, are there such
% wavelet filters? If your filterbank has different subsampling factors following the first two filters, please send a feature request.
assert(a(1)==a(2),'First two elements of *a* are not equal. Such wavelet filterbank is not suported.');

% Time-reversed, complex conjugate impulse responses.
filtNo = length(h);
%hCell = cellfun(@(hEl) conj(flipud(hEl.h(:))),h,'UniformOutput',0);
hCell = cellfun(@(hEl) hEl.h(:),h,'UniformOutput',0);

if(strcmp(ext,'per'))
   % Initial shift of the filter to compensate for it's delay.
   % "Zero" delay transform is produced
   % offset = cellfun(@(hEl) 1-numel(hEl.h)-hEl.offset,h); 
   offset = cellfun(@(hEl) hEl.offset,h); 
elseif strcmp(ext,'valid')
   offset = -cellfun(@(hEl) numel(hEl.h)-1,h);
else
   % No compensation for the filter delay (filters are made causal with respect to the output sequences).
   % This creates relative shift between levels of coefficients.
   % Initial shift determines type of subsampling. 
   % This is even subsampling. e.g. subs. [1,2,3,4,5,6] by a factor 3 becomes [3,6]
   % The number of output coefficients depends on it.
   offset = -(a-1);
   % For odd subsampling skip = 0; but it requires slight touches
   % elsewhere.
end

M = (filtNo-1)*J+1;
c = cell(M,1);
runPtr = M-filtNo+2;
ctmp = f;
for jj=1:J
    % Run filterbank
    ctmp = comp_filterbank_td(ctmp,hCell,a,offset,ext);
    % Bookkeeping
    c(runPtr:runPtr+filtNo-2) = ctmp(2:end);
    ctmp = ctmp{1};
    runPtr = runPtr - (filtNo - 1);
end
% Save final approximation coefficients
c{1} = ctmp;




       




