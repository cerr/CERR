function c=ref_ufilterbank(f,g,a);  
%-*- texinfo -*-
%@deftypefn {Function} ref_ufilterbank
%@verbatim
%REF_UFILTERBANK   Uniform filterbank by pconv
%   Usage:  c=ref_ufilterbank(f,g,a);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_ufilterbank.html}
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

N=L/a;
M=numel(g);

c=zeros(N,M,W,assert_classname(f));
  
for w=1:W
  for m=1:M
    c(:,m,w)=pfilt(f(:,w),g{m},a);
  end;
end;

  


