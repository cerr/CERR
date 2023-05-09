function c = u2nonucfmt(cu, p)
%-*- texinfo -*-
%@deftypefn {Function} u2nonucfmt
%@verbatim
%U2NONUCFMT Uniform to non-uniform filterbank coefficient format
%   Usage:  c=u2nonucfmt(cu,pk)
%
%   Input parameters:
%         cu   : Uniform filterbank coefficients.
%
%   Output parameters:
%         c    : Non-uniform filterbank coefficients.
%         p    : Numbers of copies of each filter.
%
%   c = U2NONUCFMT(cu,pk) changes the coefficient format from
%   uniform filterbank coefficients cu (M=sum(p) channels) to
%   non-uniform coefficients c (numel(p) channels)  such that each
%   channel of c consinst of p(m) interleaved channels of cu.
%
%   The output c is a cell-array in any case.
%
%
%   References:
%     S. Akkarakaran and P. Vaidyanathan. Nonuniform filter banks: New
%     results and open problems. In P. M. C.K. Chui and L. Wuytack, editors,
%     Studies in Computational Mathematics: Beyond Wavelets, volume 10, pages
%     259 --301. Elsevier B.V., 2003.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/u2nonucfmt.html}
%@seealso{nonu2ufilterbank}
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

complainif_notenoughargs(nargin,2,mfilename);

if isempty(cu)
   error('%s: cu must be non-empty.',upper(mfilename));
end

if iscell(cu)
    if any(cellfun(@isempty,cu));
      error('%s: Elements of cu must be non-empty.',upper(mfilename));
    end

    M = numel(cu);
    W = size(cu{1},2);

    Lc = size(cu{1},1);
    if any(Lc~=cellfun(@(cEl)size(cEl,1),cu))
        error('%s: Coefficient subbands do not have an uniform length',...
              upper(mfilename));
    end
elseif isnumeric(cu)
    M = size(cu,2);
    W = size(cu,3);
    Lc = size(cu,1);
else
    error('%s: cu must be a cell array or numeric.',upper(mfilename));
end

if isempty(p) || ~isvector(p)
   error('%s: p must be a non-empty vector.',upper(mfilename));
end

if sum(p) ~= M
    error(['%s: Total number of filters in p does not comply with ',...
           'number of channels'],upper(mfilename));
end

Mnonu = numel(p);
c = cell(Mnonu,1);
p = p(:);
pkcumsum = cumsum([1;p]);
crange = arrayfun(@(pEl,pcEl)pcEl:pcEl+pEl-1,p,pkcumsum(1:end-1),'UniformOutput',0);

if iscell(cu)
    for m=1:Mnonu
        ctmp = [cu{crange{m}}].';
        c{m} = reshape(ctmp(:),W,[]).';
    end
else
    for m=1:Mnonu
        c{m} = zeros(p(m)*Lc,W,assert_classname(cu));
        for w=1:W
            c{m}(:,w) = reshape(cu(:,crange{m},w).',1,[]);
        end
    end
end

% Post check whether there is the same number of coefficients
if sum(cellfun(@(cEl) size(cEl,1),c)) ~= M*Lc
    error(['%s: Invalid number of coefficients in subbands.'],upper(mfilename));
end


