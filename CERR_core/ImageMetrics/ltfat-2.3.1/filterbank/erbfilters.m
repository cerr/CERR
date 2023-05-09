function [g,a,fc,L]=erbfilters(fs,Ls,varargin)
%-*- texinfo -*-
%@deftypefn {Function} erbfilters
%@verbatim
%ERBFILTERS   ERB-spaced filters
%   Usage:  [g,a,fc,L]=erbfilters(fs,Ls);
%           [g,a,fc,L]=erbfilters(fs,Ls,...);
%
%   Input parameters:
%      fs    : Sampling rate (in Hz).
%      Ls    : Signal length.
%   Output parameters:
%      g     : Cell array of filters.
%      a     : Downsampling rate for each channel.
%      fc    : Center frequency of each channel.
%      L     : Next admissible length suitable for the generated filters.
%
%   [g,a,fc]=ERBFILTERS(fs,Ls) constructs a set of filters g that are
%   equidistantly spaced on the ERB-scale (see FREQTOERB) with bandwidths
%   that are proportional to the width of the auditory filters
%   AUDFILTBW. The filters are intended to work with signals with a
%   sampling rate of fs.
%
%   Note that this function just forwards the arguments to AUDFILTERS.
%   Please see the help of AUDFILTERS for more details.
%
%   Examples:
%   ---------
%
%   In the first example, we construct a highly redudant uniform
%   filterbank and visualize the result:
%
%     [f,fs]=greasy;  % Get the test signal
%     [g,a,fc]=erbfilters(fs,length(f),'uniform','M',100);
%     c=filterbank(f,g,a);
%     plotfilterbank(c,a,fc,fs,90,'audtick');
%
%   In the second example, we construct a non-uniform filterbank with
%   fractional sampling that works for this particular signal length, and
%   test the reconstruction. The plot displays the response of the
%   filterbank to verify that the filters are well-behaved both on a
%   normal and an ERB-scale. The second plot shows frequency responses of
%   filters used for analysis (top) and synthesis (bottom). :
%
%     [f,fs]=greasy;  % Get the test signal
%     L=length(f);
%     [g,a,fc]=erbfilters(fs,L,'fractional');
%     c=filterbank(f,{'realdual',g},a);
%     r=2*real(ifilterbank(c,g,a));
%     norm(f-r)
%
%     % Plot the response
%     figure(1);
%     subplot(2,1,1);
%     R=filterbankresponse(g,a,L,fs,'real','plot');
%
%     subplot(2,1,2);
%     semiaudplot(linspace(0,fs/2,L/2+1),R(1:L/2+1));
%     ylabel('Magnitude');
%
%     % Plot frequency responses of individual filters
%     gd=filterbankrealdual(g,a,L);
%     figure(2);
%     subplot(2,1,1);
%     filterbankfreqz(gd,a,L,fs,'plot','linabs','posfreq');
%
%     subplot(2,1,2);
%     filterbankfreqz(g,a,L,fs,'plot','linabs','posfreq');
%
%
%
%   References:
%     T. Necciari, P. Balazs, N. Holighaus, and P. L. Soendergaard. The ERBlet
%     transform: An auditory-based time-frequency representation with perfect
%     reconstruction. In Proceedings of the 38th International Conference on
%     Acoustics, Speech, and Signal Processing (ICASSP 2013), pages 498--502,
%     Vancouver, Canada, May 2013. IEEE.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/erbfilters.html}
%@seealso{audfilters, filterbank, ufilterbank, ifilterbank, ceil23}
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

% Authors: Peter L. Soendergaard, Zdenek Prusa, Nicki Holighaus

[g,a,fc,L]=audfilters(fs,Ls,varargin{:},'erb');
