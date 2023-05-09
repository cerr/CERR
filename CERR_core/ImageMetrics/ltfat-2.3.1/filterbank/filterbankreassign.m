function [sr,repos,Lc]=filterbankreassign(s,tgrad,fgrad,a,var)
%-*- texinfo -*-
%@deftypefn {Function} filterbankreassign
%@verbatim
%FILTERBANKREASSIGN  Reassign filterbank spectrogram
%   Usage:  sr = filterbankreassign(s,tgrad,fgrad,a,cfreq);
%           sr = filterbankreassign(s,tgrad,fgrad,a,g);
%           [sr,repos,Lc] = filterbankreassign(...);
%
%   Input parameters:
%      s     : Spectrogram to be reassigned.
%      tgrad : Instantaneous frequency relative to original position.
%      fgrad : Group delay relative to original position.
%      a     : Vector of time steps.
%      cfreq : Vector of relative center frequencies in ]-1,1].
%      g     : Set of filters.
%   Output parameters:
%      sr    : Reassigned filterbank spectrogram.
%      repos : Reassigned positions.
%      Lc    : Subband lengths.
%
%   FILTERBANKREASSIGN(s,tgrad,fgrad,a,cfreq) will reassign the values of
%   the filterbank spectrogram s using the group delay fgrad and
%   instantaneous frequency tgrad. The time-frequency sampling
%   pattern is determined from the time steps a and the center
%   frequencies cfreq.
%
%   FILTERBANKREASSIGN(s,tgrad,fgrad,a,g) will do the same thing except
%   the center frequencies are estimated from a set of filters g.
%
%   [sr,repos,Lc]=FILTERBANKREASSIGN(...) does the same thing, but in addition
%   returns a vector of subband lengths Lc (Lc = cellfun(@numel,s))
%   and cell array repos with sum(Lc) elements. Each element corresponds
%   to a single coefficient obtained by cell2mat(sr) and it is a vector
%   of indices identifying coefficients from cell2mat(s) assigned to
%   the particular time-frequency position.
%
%   The arguments s, tgrad and fgrad must be cell-arrays of vectors
%   of the same lengths. Arguments a and cfreq or g must have the
%   same number of elements as the cell arrays with coefficients.
%
%   Examples:
%   ---------
%
%   This example shows how to reassign a ERB filterbank spectrogram:
%
%     % Genrate 3 chirps 1 second long
%     L = 44100; fs = 44100; l = 0:L-1;
%
%     f = sin(2*pi*(l/35+(l/300).^2)) + ...
%         sin(2*pi*(l/10+(l/300).^2)) + ...
%         sin(2*pi*(l/5-(l/450).^2));
%     f = 0.7*f';
%
%     % Create ERB filterbank
%     [g,a,fc]=erbfilters(fs,L,'fractional','spacing',1/12,'warped');
%
%     % Compute phase gradient
%     [tgrad,fgrad,cs,c]=filterbankphasegrad(f,g,a);
%     % Do the reassignment
%     sr=filterbankreassign(cs,tgrad,fgrad,a,cent_freqs(fs,fc));
%     figure(1); subplot(211);
%     plotfilterbank(cs,a,fc,fs,60);
%     title('ERBlet spectrogram of 3 chirps');
%     subplot(212);
%     plotfilterbank(sr,a,fc,fs,60);
%     title('Reassigned ERBlet spectrogram of 3 chirps');
%
%
%   References:
%     N. Holighaus, Z. Průša, and P. L. Soendergaard. Reassignment and
%     synchrosqueezing for general time-frequency filter banks, subsampling
%     and processing. Signal Processing, 125:1--8, 2016. [1]http ]
%     
%     References
%     
%     1. http://www.sciencedirect.com/science/article/pii/S0165168416000141
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/filterbankreassign.html}
%@seealso{filterbankphasegrad, gabreassign}
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

%   AUTHOR : Nicki Holighaus.

% Sanity checks
complainif_notenoughargs(nargin,5,'FILTERBANKREASSIGN');

if isempty(s) || ~iscell(s)
    error('%s: s should be a nonempty cell array.',upper(mfilename));
end

if isempty(tgrad) || ~iscell(tgrad) || any(~cellfun(@isreal,tgrad))
    error('%s: tgrad should be a nonempty cell array of real vectors.',...
          upper(mfilename));
end

if isempty(fgrad) || ~iscell(fgrad) || any(~cellfun(@isreal,fgrad))
    error('%s: fgrad should be a nonempty cell array of real vectors.',...
          upper(mfilename));
end

if any(cellfun(@(sEl,tEl,fEl) ~isvector(sEl) || ~isvector(tEl) || ...
                              ~isvector(fEl), s,tgrad,fgrad))
   error('%s: s, tgrad, fgrad must be cell arrays of numeric vectors.',...
         upper(mfilename));
end

if ~isequal(size(s),size(tgrad),size(fgrad)) || ...
   any(cellfun(@(sEl,tEl,fEl) ~isequal(size(sEl),size(tEl),size(fEl)), ...
               s,tgrad,fgrad))
   error('%s: s, tgrad, fgrad does not have the same format.',upper(mfilename));
end


W = cellfun(@(sEl)size(sEl,2),s);
if any(W>1)
   error('%s: Only one-channel signals are supported.',upper(mfilename));
end

% Number of channels
M = numel(s);

% Number of elements in channels
Lc = cellfun(@(sEl)size(sEl,1),s);

% Sanitize a
a=comp_filterbank_a(a,M);
a = a(:,1)./a(:,2);

% Check if a comply with subband lengths
L = Lc.*a;
if any(abs(L-L(1))>1e-6)
   error(['%s: Subsampling factors and subband lengths do not ',...
          'comply.'],upper(mfilename));
end
L = L(1);

% Determine center frequencies
if isempty(var) || numel(var)~=M || ~isvector(var) && ~iscell(var)
   error(['%s: cfreq must be length-M numeric vector or a cell-array ',...
          'containg M filters.'],upper(mfilename));
else
    if iscell(var)
       cfreq = cent_freqs(var,L);
    else
       cfreq = var;
    end
end

% Do the computations
if nargout>1
   [sr,repos] = comp_filterbankreassign(s,tgrad,fgrad,a,cfreq);
else
   sr = comp_filterbankreassign(s,tgrad,fgrad,a,cfreq);
end


