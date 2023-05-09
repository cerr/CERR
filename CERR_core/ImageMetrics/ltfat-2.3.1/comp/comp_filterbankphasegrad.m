function [tgrad,fgrad,s] = comp_filterbankphasegrad(c,ch,cd,L,minlvl)
%-*- texinfo -*-
%@deftypefn {Function} comp_filterbankphasegrad
%@verbatim
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_filterbankphasegrad.html}
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

% Compute spectrogram and
% remove small values because we need to divide by cs
temp = cell2mat(c);
minlvl = minlvl*max(abs(temp(:)).^2);
s = cellfun(@(x) max(abs(x).^2,minlvl),c,'UniformOutput',false);

% Compute instantaneous frequency
tgrad=cellfun(@(x,y,z) real(x.*conj(y)./z)/L*2,cd,c,s,'UniformOutput',false);

% Limit 
tgrad = cellfun(@(fEl) fEl.*(abs(fEl)<=2) ,tgrad,'UniformOutput',0);

% Compute group delay
fgrad=cellfun(@(x,y,z) imag(x.*conj(y)./z),ch,c,s,'UniformOutput',false);

