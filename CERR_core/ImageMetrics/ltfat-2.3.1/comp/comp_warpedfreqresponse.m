function H=comp_warpedfreqresponse(wintype,fc,bw,fs,L,freqtoscale,scaletofreq,varargin)
%-*- texinfo -*-
%@deftypefn {Function} comp_warpedfreqresponse
%@verbatim
%COMP_WARPEDFREQRESPONSE  Transfer function of warped filter
%   Usage: H=comp_warpedfreqresponse(wintype,fc,bw,fs,L,freqtoscale);
%          H=comp_warpedfreqresponse(wintype,fc,bw,fs,L,freqtoscale,normtype);
%
%   Input parameters:
%      wintype     : Type of window (from firwin)
%      fc          : Centre frequency, in scale units.
%      bw          : Bandwith, in scale units.
%      fs          : Sampling frequency in Hz.
%      L           : Transform length (in samples).
%      freqtoscale : Function to convert Hz into scale units.
%      scaletofreq : Function to convert scale units into Hz.
%      normtype    : Normalization flag to pass to NORMALIZE.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_warpedfreqresponse.html}
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


definput.import={'normalize'};
definput.flags.symmetry = {'nonsymmetric','symmetric'};
[flags,kv]=ltfatarghelper({},definput,varargin);

fcwasnegative = fc < 0;

if fcwasnegative && flags.do_symmetric
   fc = -fc;
end

fcscale = freqtoscale(fc);

if ~flags.do_symmetric
   % Compute the values in Aud of the channel frequencies of an FFT of
   % length L.
   bins_lo   = freqtoscale(modcent(fs*(0:L-1)/L,fs)).';
else
   bins_lo   = freqtoscale(fs*(0:L-1)/L).';
end

% This one is necessary to represent the highest frequency filters, which
% overlap into the negative frequencies.
nyquest2  = 2*freqtoscale(fs/2);
bins_hi   = nyquest2+bins_lo;

% firwin makes a window of width 1 centered around 0 on the scale, so we rescale the
% bins in order to pass the correct width to firwin and subtract fc
bins_lo=(bins_lo-fcscale)/bw;
bins_hi=(bins_hi-fcscale)/bw;

pos_lo=comp_warpedfoff(fc,bw,fs,L,freqtoscale,scaletofreq,flags.do_symmetric);
% The "floor" below often cuts away a non-zero sample, but it makes
% the support stay below the limit needed for the painless case. Same
% deal 4 lines below.
pos_hi=floor(scaletofreq(fcscale+.5*bw)/fs*L);

if pos_hi>L/2
    % Filter is high pass and spilling into the negative frequencies
    pos_hi=floor(scaletofreq(fcscale+.5*bw-nyquest2)/fs*L);
end;

win_lo=firwin(wintype,bins_lo);
win_hi=firwin(wintype,bins_hi);


H=win_lo+win_hi;
H(isnan(H)) = 0;
 
H=normalize(H,flags.norm);

H=circshift(H,-pos_lo);
upidx=modcent(pos_hi-pos_lo,L);

% ------ Testing ---------------
if 0
    bb=circshift(bins_lo,-pos_lo);
    if bb(1)<-0.5
        % Adjust bin_lo
        error('Could do better here.');
    end;
    if (bb(upidx+1)<0.5) && (bb(upidx+1)>0)
        disp('Chopped non-zero sample.');
        bb(upidx+1)
    end;
end;

H=H(1:upidx);

if fcwasnegative && flags.do_symmetric
   H = H(end:-1:1);
end

