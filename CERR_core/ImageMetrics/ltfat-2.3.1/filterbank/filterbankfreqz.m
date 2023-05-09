function gf = filterbankfreqz(g,a,L,varargin)
%-*- texinfo -*-
%@deftypefn {Function} filterbankfreqz
%@verbatim
%FILTERBANKFREQZ  Filterbank frequency responses
%   Usage: gf = filterbankfreqz(g,a,L)
%
%   gf = FILTERBANKFREQZ(g,a,L) calculates length L frequency responses
%   of filters in g and returns them as columns of gf.
%
%   If an optional parameters 'plot' is passed to FILTERBANKFREQZ,
%   the frequency responses will be plotted using PLOTFFT. Any
%   optional parameter undestood by PLOTFFT can be passed in addition
%   to 'plot'.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/filterbankfreqz.html}
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

complainif_notenoughargs(nargin,3,'FILTERBANKFREQZ');
complainif_notposint(L,'L','FILTERBANKFREQZ');

% Wrap g if it is not a cell. The format of g will be checked
% further in filterbankwin.
if ~iscell(g)
    g = {g};
end

% The only place we need a
% It is necessary for cases when filterbank is given by e.g.
% {'dual',g}
g = filterbankwin(g,a,L,'normal');
M = numel(g);

G1=comp_transferfunction(g{1},L);
gf = zeros(L,M,class(G1));
gf(:,1) = G1;
for m=2:M
    gf(:,m) = cast(comp_transferfunction(g{m},L),class(G1));
end

% Search for the 'plot' flag
do_plot = any(strcmp('plot',varargin));

if do_plot
    % First remove the 'plot' flag from the arguments
    varargin(strcmp('plot',varargin)) = [];
    % and pass everything else to plotfft
    plotfft(gf,varargin{:});
end;

if nargout<1
    clear gf;
end


