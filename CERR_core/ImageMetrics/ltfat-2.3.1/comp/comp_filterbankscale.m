function g = comp_filterbankscale(g,a,scaling)


if strcmp(scaling,'scale')
    g = cellfun(@(gEl,aEl) setfield(gEl,'h',gEl.h./aEl),g(:),...
                      num2cell(a(:)),...
                      'UniformOutput',0);
elseif strcmp(scaling,'noscale')
    % Do nothing
elseif strcmp(scaling,'sqrt')
    g = cellfun(@(gEl,aEl) setfield(gEl,'h',gEl.h./sqrt(aEl)),g(:),...
                      num2cell(a(:)),...
                      'UniformOutput',0); 
else
    error('%s: Unrecognized scaling flag.',upper(mfilename) );
end  


%-*- texinfo -*-
%@deftypefn {Function} comp_filterbankscale
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_filterbankscale.html}
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

