function [gu,au,p]=nonu2ufilterbank(g,a)
%-*- texinfo -*-
%@deftypefn {Function} nonu2ufilterbank
%@verbatim
%NONU2UFILTERBANK   Non-uniform to uniform filterbank transform
%   Usage:  [gu,au]=nonu2ufilterbank(g,a)
%
%   Input parameters:
%         g     : Filters as a cell array of structs.
%         a     : Subsampling factors.
%
%   Output parameters:
%         gu    : Filters as a cell array of structs.
%         au    : Uniform subsampling factor.
%         pk    : Numbers of copies of each filter.
%
%   [gu,au]=NONU2UFILTERBANK(g,a) calculates uniform filterbank gu, 
%   au=lcm(a) which is identical to the (possibly non-uniform) filterbank
%   g, a in terms of the equal output coefficients. Each filter g{k} 
%   is replaced by p(k)=au/a(k) advanced versions of itself such that
%   z^{ma(k)}G_k(z) for m=0,...,p-1.
%
%   This allows using the factorisation algorithm when determining
%   filterbank frame bounds in FILTERBANKBOUNDS and
%   FILTERBANKREALBOUNDS and in the computation of the dual filterbank 
%   in FILTERBANKDUAL and FILTERBANKREALDUAL which do not work 
%   with non-uniform filterbanks.
%
%   One can change between the coefficient formats of gu, au and 
%   g, a using NONU2UCFMT and U2NONUCFMT in the reverse direction.
%
%
%   References:
%     S. Akkarakaran and P. Vaidyanathan. Nonuniform filter banks: New
%     results and open problems. In P. M. C.K. Chui and L. Wuytack, editors,
%     Studies in Computational Mathematics: Beyond Wavelets, volume 10, pages
%     259 --301. Elsevier B.V., 2003.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/nonu2ufilterbank.html}
%@seealso{ufilterbank, filterbank, filterbankbounds, filterbankdual}
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

complainif_notenoughargs(nargin,2,'NONU2UFILTERBANK');

try
    [g,asan] = filterbankwin(g,a,'normal');
catch
    err = lasterror;
    if strcmp(err.identifier,'L:undefined')
        % If it blotched because of the undefined L, explain that.
        % This should capture only formats like {'dual',...} and {'gauss'}
        error(['%s: Function cannot handle g in a format which ',...
               'requires L. Consider pre-formatting the filterbank by ',...
               'calling g = FILTERBANKWIN(g,a,L).'],upper(mfilename));
    else
        % Otherwise just rethrow the error
        error(err.message);
    end
end

% This function does not work for fractional subsampling
if size(asan,2)==2 && ~all(asan(:,2)==1) && rem(asan(:,1),1)~=0
   error(['%s: Filterbanks with fractional subsampling are not',...
          ' supported.'],upper(mfilename)); 
end

% This is effectivelly lcm(a)
au=filterbanklength(1,asan);

% Numbers of copies of each filter
p = au./asan(:,1);

if all(asan(:,1)==asan(1,1))
    % Filterbank is already uniform, there is nothing to be done.
    gu = g;
    au = asan;
    return;
end

% Do the actual filter copies
% This only changes .delay or .offset
gu=cell(sum(p),1);
auIdx = 1;
for m=1:numel(g)
   for ii=0:p(m)-1
      gu{auIdx} = g{m};
      if(isfield(gu{auIdx},'H'))
         if(~isfield(gu{auIdx},'delay'))
            gu{auIdx}.delay = 0;
         end
         gu{auIdx}.delay = gu{auIdx}.delay-asan(m)*ii;
      end
      
      if(isfield(gu{auIdx},'h'))
         if(~isfield(gu{auIdx},'offset'))
            gu{auIdx}.offset = 0;
         end
         gu{auIdx}.offset = gu{auIdx}.offset-asan(m)*ii;
      end
      auIdx = auIdx+1;
   end
end



