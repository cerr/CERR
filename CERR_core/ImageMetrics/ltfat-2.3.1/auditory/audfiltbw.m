function bw = audfiltbw(fc,varargin)
%-*- texinfo -*-
%@deftypefn {Function} audfiltbw
%@verbatim
%AUDFILTBW  Bandwidth of auditory filter
%   Usage: bw = audfiltbw(fc)
%
%   AUDFILTBW(fc) returns the critical bandwidth of the auditory filter 
%   at center frequency fc defined in equivalent rectangular bandwidth.
%   The function uses the relation:
%
%      bw = 24.7 + fc/9.265
%
%   as estimated in Glasberg and Moore (1990). This function is also used
%   when the original ERB scale ('erb83') is chosen.
% 
%   AUDFILTBW(fc,'bark') returns the critical bandwidth at fc according
%   to the Bark scale using the relation:
% 
%      bw = 25 + 75 ( 1+1.4*10^{-6} fc^2 )^0.69
%
%   as estimated by Zwicker and Terhardt (1980).
%
%   For the scales 'mel', 'mel1000', 'log10' and 'semitone', no critical
%   bandwidth function is usually given. Following the example of the
%   equivalent rectangular bandwidth (associated with the ERB scale), we
%   use the derivative of the inverse of the scale function F_{Scale},
%   evaluated at F_{Scale}(fc), i.e. 
% 
%      bw = (F_{scale}^{-1})'(F_{scale}(fc))
%
%
%   References:
%     E. Zwicker and E. Terhardt. Analytical expressions for criticalband
%     rate and critical bandwidth as a function of frequency. The Journal of
%     the Acoustical Society of America, 68(5):1523--1525, 1980. [1]http ]
%     
%     B. R. Glasberg and B. Moore. Derivation of auditory filter shapes from
%     notched-noise data. Hearing Research, 47(1-2):103, 1990.
%     
%     References
%     
%     1. http://scitation.aip.org/content/asa/journal/jasa/68/5/10.1121/1.385079
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/auditory/audfiltbw.html}
%@seealso{freqtoerb, erbspace, freqtoaud, audtofreq}
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
  
%   AUTHOR : Peter L. Soendergaard
  
% ------ Checking of input parameters ---------
  
% narginchk(1,1);
if nargin<1
  error('%s: Too few input parameters.',upper(mfilename));
end;

if ~isnumeric(fc) || any(fc(:)<0)
  error('AUDFILTBW: fc must be non-negative.');
end;

definput.flags.audscale={'erb','erb83','bark','mel','mel1000','log10','semitone'};
[flags,kv]=ltfatarghelper({},definput,varargin);

% ------ Computation --------------------------

% FIXME: What is the upper frequency for which the estimation is valid?
if flags.do_erb || flags.do_erb83
    bw = 24.7 + fc/9.265;
end

if flags.do_bark
    bw = 25 + 75*(1 + 1.4E-6*fc.^2).^0.69;
end

if flags.do_mel    
    bw = log(17/7)*(700+fc)/1000;
end

if flags.do_mel1000  
    bw = log(2)*(1+fc/1000);
end;

if flags.do_log10 || flags.do_semitone
    bw = fc;
end

