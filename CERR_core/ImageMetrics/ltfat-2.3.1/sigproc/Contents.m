% LTFAT - Signal processing tools
%
%  Peter L. Soendergaard, 2007 - 2018.
%
%  General
%    RMS            -  Root Mean Square norm of signal.
%    NORMALIZE      -  Normalize signal by specified norm.
%    GAINDB         -  Scale input signal
%    CRESTFACTOR    -  Compute the crest factor of a signal.
%    UQUANT         -  Simulate uniform quantization.
%
%  Window functions
%    FIRWIN         -  FIR windows (Hanning,Hamming,Blackman,...).
%    FIRKAISER      -  FIR Kaiser-Bessel window.
%    FIR2LONG       -  Extend FIR window to LONG window.
%    LONG2FIR       -  Cut LONG window to FIR window.
%    FREQWIN        -  Freq responses (Gauss,Gammatone,Butterworth,...)
%
%  Filtering
%    FIRFILTER      -  Construct an FIR filter.
%    BLFILTER       -  Construct a band-limited filter.
%    WARPEDBLFILTER -  Warped, band-limited filter.
%    FREQFILTER     -  Construct a full length frequency side filter.
%    PFILT          -  Apply filter with periodic boundary conditions.
%    MAGRESP        -  Magnitude response plot.
%    TRANSFERFUNCTION - Compute the transfer function of a filter.
%    PGRPDELAY      -  Periodic Group Delay
%
%  Ramping
%    RAMPUP         -  Rising ramp.
%    RAMPDOWN       -  Falling ramp.
%    RAMPSIGNAL     -  Ramp a signal.
%
%  Thresholding methods
%    THRESH         -  Coefficient thresholding.
%    LARGESTR       -  Keep largest ratio of coefficients.
%    LARGESTN       -  Keep N largest coefficients.
%    DYNLIMIT       -  Limit the dynamical range.
%    GROUPTHRESH    -  Group thresholding.
%
%  Image processing
%    RGB2JPEG       -  Convert RGB values to the JPEG colour model
%    JPEG2RGB       -  Convert values from the JPEG colour model to RGB
%
%  Tools for OFDM
%    QAM4           -  Quadrature amplitude modulation, order 4
%    IQAM4          -  Inverse QAM of order 4
%
%  For help, bug reports, suggestions etc. please visit 
%  http://github.com/ltfat/ltfat/issues
%
%
%   Url: http://ltfat.github.io/doc/sigproc/Contents.html

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

