function [gout,a,fc,L,info] = gabfilters(Ls,g,a,M,varargin)
%GABFILTERS Constructs Gabor filters
%   Usage:  [gout,aout,fc,L]=gabfilters(Ls,g,a,M);
%
%   Input parameters:
%      Ls    : Signal length.
%      g     : Window
%      a     : Hop factor
%      M     : Number of channels
%   Output parameters:
%      gout  : Cell array of filters.
%      aout  : Downsampling rate for each channel.
%      fc    : Center frequencies normalized to the Nyquist rate
%      L     : Next admissible length suitable for the generated filters. 
%
%   GABFILTERS(Ls,g,a,M) constructs a linear frequency Gabor filters
%   as modulations of a prototype window g using hop size a and number 
%   of channels M. The filterbank is only valid for the system length 
%   dgtlength(Ls,a,M). The filterbank acts exactly like DGTREAL 
%   (there is M2=floor(M/2)+1 filters) with the 'timeinv' phase 
%   convention i.e. the following should be close of zero:
%
%       M = 512; a = 128; L = 10*512; g = 'hann';
%       f = randn(L,1);
%       c1 = dgtreal(f,g,a,M,'timeinv');
%       [gfb,afb] = gabfilters(L,g,a,M);
%       c2 = ufilterbank(f,gfb,afb);
%       norm(c1 - c2.')  
%
%   !!!Note!!! that the this function is not suitable for long signals. 
%   Using DGTREAL and DGT directly will be much faster.
%
%   Additional paramaters
%   ---------------------
%
%   'real' (default) or 'complex'
%       'real' mimics DGTREAL, 'complex' mimics DGT
%       
%   'time' (default) or 'freq'
%       The specified window g is applied either in the time domain 
%       or in the frequency domain.
%
%   See also: dgtreal dgt
%
%
%   Url: http://ltfat.github.io/doc/filterbank/gabfilters.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

%AUTHOR: Nicki Holighaus, Zdenek Prusa

if nargin<4, error('%s: Too few input parameters.',upper(mfilename)); end

definput.flags.real={'real','complex'};
definput.flags.windowaxis={'time','freq'};
[flags]=ltfatarghelper({},definput,varargin);

L = dgtlength(Ls,a,M);
[g0, wininfo] = gabwin(g,a,M,L);

fc = 2*(0:M-1).'/M;
Mfull = M;

if flags.do_time
    gnum = fftshift(fft(involute(fir2long(g0,L))));
else
    gnum = conj(fftshift(g0));
end

Lg = numel(gnum);

if flags.do_real
    M = floor(M/2) + 1;
    fc = postpad(fc,M);
end

gout = cell(M,1);

for kk = 0:M-1
    gtmp.H = gnum;
    gtmp.foff = kk*L/Mfull-floor(Lg/2);
    gtmp.realonly = 0; 
    gtmp.L = L;
    gout{kk+1} = gtmp;
end

info.fc = fc;

% Use tfr of a Gaussian with the same width at ~half of the rel. height 
tfrfunc = comp_tfrfromwin(g0,10^(-3/10));
info.tfr = tfrfunc(L);

if ~flags.do_time
    info.tfr = 1/info.tfr; 
end

