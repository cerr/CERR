function definput=arg_firwin(definput)
 
truncgaussflags = {'truncgauss'};

definput.flags.wintype=[{...
    'hanning','hann','sine','cosine', 'sqrthann','hamming', 'square',...
    'rect', 'tria','bartlett', 'triangular','sqrttria','blackman',...
    'blackman2', 'nuttall','nuttall10','nuttall01','nuttall20',...
    'nuttall11','nuttall03', 'nuttall12','nuttall21', 'nuttall30',...
    'ogg', 'itersine', 'nuttall02'}, truncgaussflags ];


%-*- texinfo -*-
%@deftypefn {Function} arg_firwin
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/arg_firwin.html}
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

