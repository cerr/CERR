function cfreq = cent_freqs(g,L)
%-*- texinfo -*-
%@deftypefn {Function} cent_freqs
%@verbatim
%CENT_FREQS   Determine relative center frequencies
%   Usage:  cfreq = cent_freqs(g);
%           cfreq = cent_freqs(g,L);
%           cfreq = cent_freqs(fs,fc);
%           cfreq = cent_freqs(g,fc);
%
%   Input parameters:
%      g     : Set of filters.
%      L     : Signal length.
%      fs    : Sampling rate (in Hz).
%      fc    : Vector of center frequencies (in Hz).
%   Output parameters:
%      cfreq : Vector of relative center frequencies in ]-1,1].
%
%   CENT_FREQS(g) will compute the center frequencies of the filters 
%   contained in g by determining their circular center of gravity. To
%   that purpose, the transfer function of each filter will be computed for
%   a default signal length on 10000 samples. For improved accuracy, the 
%   factual signal length L can be supplied as an optional parameter.
%   Alternatively, the center frequencies can be obtained from a set of
%   center frequencies fc (in Hz) and the sampling rate fs. The
%   sampling rate can also be determined from the field fs of the filter
%   set g.
%
%   Note: If g.H contains full-length, numeric transfer functions, L*
%   must be specified for correct results.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/cent_freqs.html}
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

complainif_notenoughargs(nargin,1,'FILTERBANKCENTFREQS');

if nargin > 1 % Try to determine cfreq from fc and fs in Hz
    if numel(g) == 1 && isnumeric(g) && numel(L) > 1
        cfreq = modcent(2*L/g,2);
        return
    elseif numel(g) == numel(L) && ( numel(g) > 1 || isfield(g,'fs') ) 
        cfreq = cellfun(@(fcEl,gEl) modcent(2*fcEl/gEl.fs,2),num2cell(L),g.');
        return
    end
else
    L = 10000; % Default value
end

g = filterbankwin(g,1,L,'normal');

% Compute l1-normalized absolute value of the transfer functions 
gH = cellfun(@(gEl) comp_transferfunction(gEl,L),g,'UniformOutput',false);
gH = cellfun(@(gHEl) abs(gHEl)./norm(gHEl,1),gH,'UniformOutput',false);

% Compute circular center of gravity
circInd = exp(2*pi*1i*(0:L-1)/L).';
cfreq = cellfun(@(gHEl) sum(circInd.*gHEl),gH.');
cfreq = real((pi*1i)\log(cfreq));   
 

