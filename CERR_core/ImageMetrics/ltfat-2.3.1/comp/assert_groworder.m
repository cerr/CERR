function order=assert_groworder(order)
%-*- texinfo -*-
%@deftypefn {Function} assert_groworder
%@verbatim
%ASSERT_GROWORDER  Grow the order parameter
%
%   ASSERT_GROWORDER is meant to be used in conjunction with
%   assert_sigreshape_pre and assert_sigreshape_post. It is used to
%   modify the order parameter in between calls in order to expand the
%   processed dimension by 1, i.e. for use in a routine that creates 2D
%   output from 1D input, for instance in dgt or filterbank.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/assert_groworder.html}
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
  
if numel(order)>1
  % We only need to handle the non-trivial order, where dim>1
  
  p=order(1);
  
  % Shift orders higher that the working dimension by 1, to make room for
  % the new dimension, but leave lower dimensions untouched.
  order(order>p)=order(order>p)+1;
  
  order=[p,p+1,order(2:end)];
end;



