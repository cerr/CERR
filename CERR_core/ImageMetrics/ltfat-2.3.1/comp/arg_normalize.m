function definput=arg_normalize(definput)
  
%-*- texinfo -*-
%@deftypefn {Function} arg_normalize
%@verbatim
% Both 'null' and 'empty' do no scaling when normalize is called
% directly.
% When used in different functions,
% 'empty' can be set as default by definput.importdefaults={'empty'};
% to detect whether any of the other flags were set.
% 
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/arg_normalize.html}
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
definput.flags.norm={'2','1','inf','area','energy','peak',...
                     's0','rms','null','wav','norm_notset'};



