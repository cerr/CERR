function cu = nonu2ucfmt(c, p)
%-*- texinfo -*-
%@deftypefn {Function} nonu2ucfmt
%@verbatim
%NONU2UCFMT Non-uniform to uniform filterbank coefficient format
%   Usage:  cu=nonu2ucfmt(c,pk)
%
%   Input parameters:
%         c   : Non-uniform filterbank coefficients.
%
%   Output parameters:
%         cu  : Uniform filterbank coefficients.
%         p   : Numbers of copies of each filter.
%
%   cu = NONU2UCFMT(c,p) changes the coefficient format from
%   non-uniform filterbank coefficients c (M=numel(p) channels) to
%   uniform coefficients c (sum(p) channels)  such that each
%   channel of cu consinst of de-interleaved samples of channels of c.
%
%   The output cu is a cell-array in any case.
%
%
%   References:
%     S. Akkarakaran and P. Vaidyanathan. Nonuniform filter banks: New
%     results and open problems. In P. M. C.K. Chui and L. Wuytack, editors,
%     Studies in Computational Mathematics: Beyond Wavelets, volume 10, pages
%     259 --301. Elsevier B.V., 2003.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/nonu2ucfmt.html}
%@seealso{nonu2ufilterbank, u2nonucfmt}
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

if isempty(c)
   error('%s: c must be non-empty.',upper(mfilename));
end

if isempty(p) || ~isvector(p)
   error('%s: pk must be a non-empty vector.',upper(mfilename));
end

if iscell(c)
    M = numel(c);
    Lc = cellfun(@(cEl) size(cEl,1),c);
    if all(Lc==Lc(1))
        if ~all(p==1) || numel(p)~=M
           error('%s: Bad format of p for uniform coefficients.',...
              upper(mfilename));
        else
            cu = c;
            % End here, this is already uniform.
            return;
        end
    end
elseif isnumeric(c)
    M = size(c,2);
    if ~all(p==1) || numel(p)~=M
        error('%s: Bad format of p for uniform coefficients.',...
               upper(mfilename));
    end
    % Just convert to cell-array and finish
    cu = cell(M,1);
    for m=1:M
        cu{m}=squeeze(c(:,m,:));
    end;
    % End here, there is nothing else to do.
    return;
else
    error('%s: c must be a cell array or numeric.',upper(mfilename));
end

if numel(p) ~= M
    error(['%s: Number of elements of p does not comply with ',...
           'number of channels passed.'],upper(mfilename));
end


p = p(:);
Mu = sum(p);
cu = cell(Mu,1);

pkcumsum = cumsum([1;p]);
crange = arrayfun(@(pEl,pcEl)pcEl:pcEl+pEl-1,p,pkcumsum(1:end-1),...
                  'UniformOutput',0);

% c can be only cell array at this point
for m=1:M
   for k=1:p(m)
      cu{crange{m}(k)} = c{m}(k:p(m):end,:);
   end
end

% Post check whether the output is really uniform and the numbers of
% coefficients are equal
Lcu = cellfun(@(cEl) size(cEl,1),cu);
if any(Lcu~=Lcu(1)) || sum(Lcu)~=sum(Lc)
    error(['%s: The combination of c and p does not result in uniform ',...
           'coefficients.'],upper(mfilename));
end



