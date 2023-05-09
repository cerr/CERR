function f = comp_iufwt(c,g,a,J,scaling)
%-*- texinfo -*-
%@deftypefn {Function} comp_iufwt
%@verbatim
%COMP_IUFWT Compute Inverse Undecimated DWT
%   Usage:  f = comp_iufwt(c,g,J,a);
%
%   Input parameters:
%         c     : L*M*W array of coefficients, M=J*(filtNo-1)+1.
%         g     : Synthesis wavelet filters-Cell-array of length filtNo.
%         J     : Number of filterbank iterations.
%         a     : Upsampling factors - array of length filtNo.
%
%   Output parameters:
%         f     : Reconstructed data - L*W array.
%
% 
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_iufwt.html}
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

% For holding the impulse responses.
filtNo = length(g);
gOffset = cellfun(@(gEl) gEl.offset,g(:));

% Optionally scale the filters
g = comp_filterbankscale(g(:),a(:),scaling);

%Change format to a matrix
gMat = cell2mat(cellfun(@(gEl) gEl.h(:),g(:)','UniformOutput',0));

% Read top-level appr. coefficients.
ca = squeeze(c(:,1,:));
cRunPtr = 2;
for jj=1:J
   % Current iteration filter upsampling factor.
   filtUps = a(1)^(J-jj); 
   % Zero index position of the upsampled filetrs.
   offset = filtUps.*gOffset ;%+ filtUps; 
   % Run the filterbank
   ca=comp_iatrousfilterbank_td([reshape(ca,size(ca,1),1,size(ca,2)),...
                 c(:,cRunPtr:cRunPtr+filtNo-2,:)],gMat,filtUps,offset); 
   % Bookkeeping
   cRunPtr = cRunPtr + filtNo -1;
end
% Copy to the output.
f = ca;
    

