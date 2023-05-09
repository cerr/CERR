function c = comp_ufwt(f,h,a,J,scaling)
%-*- texinfo -*-
%@deftypefn {Function} comp_ufwt
%@verbatim
%COMP_UFWT Compute Undecimated DWT
%   Usage:  c=comp_ufwt(f,h,J,a);
%
%   Input parameters:
%         f     : Input data - L*W array.
%         h     : Analysis Wavelet filters - cell-array of length filtNo.
%         J     : Number of filterbank iterations.
%         a     : Subsampling factors - array of length filtNo.
%
%   Output parameters:
%         c     : L*M*W array of coefficients, where M=J*(filtNo-1)+1.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_ufwt.html}
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
% wavelet filters? If your filterbank has different subsampling factors after first two filters, please send a feature request.
assert(a(1)==a(2),'First two elements of a are not equal. Such wavelet filterbank is not suported.');

% For holding the time-reversed, complex conjugate impulse responses.
filtNo = length(h);
% Optionally scale the filters
h = comp_filterbankscale(h(:),a(:),scaling);
%Change format to a matrix
%hMat = cell2mat(cellfun(@(hEl) conj(flipud(hEl.h(:))),h(:)','UniformOutput',0));
hMat = cell2mat(cellfun(@(hEl) hEl.h(:),h(:)','UniformOutput',0));

%Delays
%hOffset = cellfun(@(hEl) 1-numel(hEl.h)-hEl.offset,h(:));
hOffset = cellfun(@(hEl) hEl.offset,h(:));

% Allocate output
[L, W] = size(f);
M = J*(filtNo-1)+1;
c = zeros(L,M,W,assert_classname(f,hMat));

ca = f;
runPtr = size(c,2) - (filtNo-2);
for jj=1:J
    % Zero index position of the upsampled filters.
    offset = a(1)^(jj-1).*(hOffset);
    % Run filterbank.
    ca=comp_atrousfilterbank_td(ca,hMat,a(1)^(jj-1),offset);
    % Bookkeeping
    c(:,runPtr:runPtr+filtNo-2,:)=ca(:,2:end,:);
    ca = squeeze(ca(:,1,:));
    runPtr = runPtr - (filtNo - 1);
end
% Saving final approximation coefficients.
c(:,1,:) = ca;


