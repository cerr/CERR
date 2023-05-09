function fftgram(f, varargin)
%-*- texinfo -*-
%@deftypefn {Function} fftgram
%@verbatim
%FFTGRAM Plot the energy of the discrete Fourier transform
%   Usage:  fftgram(f)
%           fftgram(f, fs)
%
%   FFTGRAM(f) plots the energy of the discrete Fourier transform computed 
%   from the function f. The function forms a Fourier pair with the periodic
%   autocorrelation function.
%
%   FFTGRAM(f,fs) does the same for a signal sampled with a sampling
%   frequency of fs Hz. If fs is no specified, the plot will display
%   normalized frequencies.
%
%   FFTGRAM(f,fs,dynrange) additionally specifies the dynamic range to
%   display on the figure.
%
%   Additional arguments for FFTGRAM:
%
%      'db'      Plots the energy on a dB scale. This is the default.
%
%      'lin'     Plots the energy on a linear scale.
%
%   In addition to these parameters, FFTGRAM accepts any of the flags from
%   NORMALIZE. The input signal will be normalized as specified.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/fftgram.html}
%@seealso{dft, plotfft}
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

% AUTHOR: Jordy van Velthoven

% Assert correct number of input parameters.
complainif_notenoughargs(nargin, 1, 'FFTGRAM');

definput.import={'ltfattranslate','normalize'};
definput.keyvals.fs=[];
definput.keyvals.clim=[];
definput.keyvals.dynrange=[];  
definput.flags.powscale={'db', 'lin'};

[flags, kv] = ltfatarghelper({'fs','dynrange'},definput,varargin);

if isreal(f)
  p = (fftreal(f).*conj(fftreal(f)));
else
  p = (fft(f).*conj(fft(f)));
end;

p = normalize(p, flags.norm);

if flags.do_db
  if isreal(f)
    plotfftreal(p,kv.fs, kv.dynrange);
  else
    plotfft(p,kv.fs, kv.dynrange);
  end;
  ylabel('Energy (dB)');
end;

if flags.do_lin
  if isreal(f)
    plotfftreal(p, kv.fs, kv.dynrange, 'lin');
  else 
    plotfft(p, kv.fs, kv.dynrange,'lin');
  end;
  ylabel('Energy');
end;

