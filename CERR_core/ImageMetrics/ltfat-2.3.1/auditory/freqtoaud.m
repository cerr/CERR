function aud = freqtoaud(freq,varargin);
%-*- texinfo -*-
%@deftypefn {Function} freqtoaud
%@verbatim
%FREQTOAUD  Converts frequencies (Hz) to auditory scale units
%   Usage: aud = freqtoaud(freq,scale);
%
%   FREQTOAUD(freq,scale) converts values on the frequency scale (measured
%   in Hz) to values on the selected auditory scale. The value of the
%   parameter scale determines the auditory scale:
%
%     'erb'     A distance of 1 erb is equal to the equivalent rectangular
%               bandwidth of the auditory filters at that point on the
%               frequency scale. The scale is normalized such that 0 erbs
%               corresponds to 0 Hz. The width of the auditory filters were
%               determined by a notched-noise experiment. The erb scale is
%               defined in Glasberg and Moore (1990). This is the default.
%
%     'mel'     The mel scale is a perceptual scale of pitches judged by
%               listeners to be equal in distance from one another. The
%               reference point between this scale and normal frequency
%               measurement is defined by equating a 1000 Hz tone, 40 dB above
%               the listener's threshold, with a pitch of 1000 mels.
%               The mel-scale is defined in Stevens et. al (1937).
%
%     'mel1000'  Alternative definition of the mel scale using a break
%                frequency of 1000 Hz. This scale was reported in Fant (1968). 
%
%     'bark'    The bark-scale is originally defined in Zwicker (1961). A
%               distance of 1 on the bark scale is known as a critical
%               band. The implementation provided in this function is
%               described in Traunmuller (1990).
%
%     'erb83'   This is the original defintion of the erb scale given in
%               Moore. et al. (1983).
%
%     'freq'    Return the frequency in Hz. 
%
%   If no flag is given, the erb-scale will be selected.
%
%
%   References:
%     S. Stevens, J. Volkmann, and E. Newman. A scale for the measurement of
%     the psychological magnitude pitch. J. Acoust. Soc. Am., 8:185, 1937.
%     
%     E. Zwicker. Subdivision of the audible frequency range into critical
%     bands (frequenzgruppen). J. Acoust. Soc. Am., 33(2):248--248, 1961.
%     [1]http ]
%     
%     G. Fant. Analysis and synthesis of speech processes. In B. Malmberg,
%     editor, Manual of phonetics. North-Holland, 1968.
%     
%     B. R. Glasberg and B. Moore. Derivation of auditory filter shapes from
%     notched-noise data. Hearing Research, 47(1-2):103, 1990.
%     
%     H. Traunmuller. Analytical expressions for the tonotopic sensory scale.
%     J. Acoust. Soc. Am., 88:97, 1990.
%     
%     B. Moore and B. Glasberg. Suggested formulae for calculating
%     auditory-filter bandwidths and excitation patterns. J. Acoust. Soc.
%     Am., 74:750, 1983.
%     
%     References
%     
%     1. http://link.aip.org/link/?JAS/33/248/1
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/auditory/freqtoaud.html}
%@seealso{freqtoaud, audspace, audfiltbw}
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
  
%   AUTHOR: Peter L. Soendergaard

%% ------ Checking of input parameters ---------

if nargin<1
  error('%s: Too few input parameters.',upper(mfilename));
end;

if ~isnumeric(freq) 
  error('%s: freq must be number.',upper(mfilename));
end;

definput.import={'freqtoaud'};
[flags,kv]=ltfatarghelper({},definput,varargin);

%% ------ Computation --------------------------


if flags.do_mel
  aud = 1000/log(17/7)*sign(freq).*log(1+abs(freq)/700);
end;

if flags.do_mel1000
  aud = 1000/log(2)*sign(freq).*log(1+abs(freq)/1000);
end;

if flags.do_erb
  % There is a round-off error in the Glasberg & Moore paper, as
  % 1000/(24.7*4.37)*log(10) = 21.332 and not 21.4 as they state.
  % The error is tiny, but may be confusing.
  % On page 37 of the paper, there is Fortran code with yet another set
  % of constants:
  %     2302.6/(24.673*4.368)*log10(1+freq*0.004368);
  aud = 9.2645*sign(freq).*log(1+abs(freq)*0.00437);
end;

if flags.do_bark
  % The bark scale seems to have several different approximations available.
  
  % This one was found through http://www.ling.su.se/STAFF/hartmut/bark.htm
  aud = sign(freq).*((26.81./(1+1960./abs(freq)))-0.53);
  
  % The one below was found on Wikipedia.
  %aud = 13*atan(0.00076*freq)+3.5*atan((freq/7500).^2);
end;

if flags.do_erb83
  aud = 11.17*sign(freq).*(log((abs(freq)+312)./(abs(freq)+14675)) ...
        - log(312/14675));
end;

if flags.do_freq
  aud = freq;
end;

if flags.do_log10 || flags.do_semitone
   aud = log10(freq);
end

