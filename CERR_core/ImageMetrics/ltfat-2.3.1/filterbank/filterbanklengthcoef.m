function L=filterbanklengthcoef(coef,a)
%-*- texinfo -*-
%@deftypefn {Function} filterbanklengthcoef
%@verbatim
%FILTERBANKLENGTHCOEF  Filterbank length from coefficients
%   Usage: L=filterbanklengthcoef(coef,a);
%
%   FILTERBANKLENGTHCOEF(coef,a) returns the length of a filterbank with
%   time-shifts a, such that the filterbank is long enough to expand the
%   coefficients coef.
%
%   If instead a signal is given, call FILTERBANKLENGTH.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/filterbanklengthcoef.html}
%@seealso{filterbank, filterbanklength}
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

complainif_notenoughargs(nargin,2,upper(mfilename));


if iscell(coef)
  cl=cellfun(@(x) size(x,1),coef);
else
  Mcoef=size(coef,2);
  cl=ones(1,Mcoef)*size(coef,1);
end;

cl=cl(:);

% Make 'a' have the length of '
if isvector(a)
    a=bsxfun(@times,a,ones(numel(cl),1));
    a=a(:);

    L=a.*cl;
else
    L=a(:,1).*cl./a(:,2);
end;


if var(L)>0
  error(['%s: Invalid set of coefficients. The product of the no. of ' ...
         'coefficients and the channel time shift must be the same for ' ...
         'all channels.'],upper(mfilename));
end;

L=L(1);



