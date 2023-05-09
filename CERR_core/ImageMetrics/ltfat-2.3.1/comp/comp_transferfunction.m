function H=comp_transferfunction(g,L)
%-*- texinfo -*-
%@deftypefn {Function} comp_transferfunction
%@verbatim
%COMP_TRANSFERFUNCTION  Compute the transfer function
%
%  COMP_TRANSFERFUNCTION(g,L) computes length L transfer function 
%  (frequency response) of a single filter g. This function can only
%  handle filters in a proper internal format i.e. already processed by
%  FILTERBANKWIN.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_transferfunction.html}
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

% Setting crossover to 0 ensures FIR filters to be transformed to 
% full-length Frequency-domain defined filters with g.H and g.foff fields.
g = comp_filterbank_pre({g},1,L,0);
% Band-limited filters have to be made full-length
H = circshift(postpad(g{1}.H(:),L),g{1}.foff);

% Realonly has to be treated separatelly for band-limited filters
if isfield(g,'realonly') && g.realonly
     H=(H+involute(H))/2;
end;


