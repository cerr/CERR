function complainif_isjavaheadless(callfun)
%-*- texinfo -*-
%@deftypefn {Function} complainif_isjavaheadless
%@verbatim
% COMPLAINIF_ISJAVAHEADLESS 
%
%   Prints warning if the available JRE ius in headless mode.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/complainif_isjavaheadless.html}
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

if nargin<1
    callfun=mfilename;
end

try
   ge = javaMethod('getLocalGraphicsEnvironment','java.awt.GraphicsEnvironment');
catch
    % No java support at all. Either we are running matlab -nojvm
    % or octave(<3.8.0) without octave-java package.
    % Both cases shoud have already been caught somewhere.   
    return;
end

if javaMethod('isHeadless',ge)
       error(['%s: JRE is available in headless mode only. ',...
              'Block processing GUI will not work. Consider ',...
              'installing full JRE.'],upper(callfun));
end

