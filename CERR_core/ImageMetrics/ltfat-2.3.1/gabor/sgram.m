function varargout=sgram(f,varargin)
%-*- texinfo -*-
%@deftypefn {Function} sgram
%@verbatim
%SGRAM  Spectrogram
%   Usage: sgram(f,op1,op2, ... );
%          sgram(f,fs,op1,op2, ... );
%          C=sgram(f, ... );
%
%   SGRAM(f) plots a spectrogram of f using a Discrete Gabor Transform (DGT).
%
%   SGRAM(f,fs) does the same for a signal with sampling rate fs (sampled
%   with fs samples per second);
%
%   SGRAM(f,fs,dynrange) additionally limits the dynamic range of the
%   plot. See the description of the 'dynrange' parameter below.
%
%   C=SGRAM(f, ... ) returns the image to be displayed as a matrix. Use this
%   in conjunction with imwrite etc. These coefficients are *only* intended to
%   be used by post-processing image tools. Numerical Gabor signal analysis
%   and synthesis should *always* be done using the DGT, IDGT, DGTREAL and
%   IDGTREAL functions.
%
%   Additional arguments can be supplied like this:
%
%       sgram(f,fs,'dynrange',50)
%
%   The arguments must be character strings possibly followed by an
%   argument:
%
%     'dynrange',r  Limit the dynamical range to r by using a colormap in
%                   the interval [chigh-r,chigh], where chigh is the highest
%                   value in the plot. The default value of [] means to not
%                   limit the dynamical range.
%    
%     'db'         Apply 20*log10 to the coefficients. This makes it possible to
%                  see very weak phenomena, but it might show too much noise. A
%                  logarithmic scale is more adapted to perception of sound.
%                  This is the default.
%    
%     'lin'        Show the energy of the coefficients on a linear scale.
%    
%     'tfr',v      Set the ratio of frequency resolution to time resolution.
%                  A value v=1 is the default. Setting v>1 will give better
%                  frequency resolution at the expense of a worse time
%                  resolution. A value of 0<v<1 will do the opposite.
%    
%     'wlen',s     Window length. Specifies the length of the window
%                  measured in samples. See help of PGAUSS on the exact
%                  details of the window length.
%
%     'posfreq'    Display only the positive frequencies. This is the
%                  default for real-valued signals.
%    
%     'nf'         Display negative frequencies, with the zero-frequency
%                  centered in the middle. For real signals, this will just
%                  mirror the upper half plane. This is standard for complex
%                  signals.
%    
%     'tc'         Time centering. Move the beginning of the signal to the
%                  middle of the plot. This is useful for visualizing the
%                  window functions of the toolbox.
%    
%     'image'      Use imagesc to display the spectrogram. This is the
%                  default.
%    
%     'clim',clim  Use a colormap ranging from clim(1) to clim(2). These
%                  values are passed to imagesc. See the help on imagesc.
%    
%     'thr',r      Keep only the largest fraction r of the coefficients, and
%                  set the rest to zero.
%    
%     'fmax',y     Display y as the highest frequency. Default value of []
%                  means to use the Nyquist frequency.
%    
%     'xres',xres  Approximate number of pixels along x-axis / time.
%                  The default value is 800
%    
%     'yres',yres  Approximate number of pixels along y-axis / frequency
%                  The Default value is 600
%    
%     'contour'    Do a contour plot to display the spectrogram.
%           
%     'surf'       Do a surf plot to display the spectrogram.
%    
%     'colorbar'   Display the colorbar. This is the default.
%    
%     'nocolorbar'  Do not display the colorbar.
%
%   In addition to these parameters, SGRAM accepts any of the flags from
%   NORMALIZE. The window used to calculate the spectrogram will be
%   normalized as specified.
%
%   Examples:
%   ---------
%
%   The GREASY signal is sampled using a sampling rate of 16 kHz. To
%   display a spectrogram of GREASY with a dynamic range of 90 dB, use:
%
%     sgram(greasy,16000,90);
%
%   To create a spectrogram with a window length of 20ms (which is
%   typically used in speech analysis) use :
%
%     fs=16000;
%     sgram(greasy,fs,90,'wlen',round(20/1000*fs));
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/sgram.html}
%@seealso{dgt, dgtreal}
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

%   AUTHOR : Peter L. Soendergaard.
%   TESTING: NA
%   REFERENCE: NA
  
if nargin<1
  error('Too few input arguments.');
end;

if sum(size(f)>1)>1
  error('Input must be a vector.');
end;

definput.import={'ltfattranslate','normalize','tfplot'};
% Override the setting from tfplot, because SGRAM does not support the
% 'dbsq' setting (it does not make sense).
definput.flags.log={'db','lin'};

% Define initial value for flags and key/value pairs.
definput.flags.wlen={'nowlen','wlen'};
definput.flags.thr={'nothr','thr'};

if isreal(f)
  definput.flags.posfreq={'posfreq','nf'};
else
  definput.flags.posfreq={'nf','posfreq'};
end;

definput.keyvals.tfr=1;
definput.keyvals.wlen=0;
definput.keyvals.thr=0;
definput.keyvals.fmax=[];
definput.keyvals.xres=800;
definput.keyvals.yres=600;

[flags,kv,fs]=ltfatarghelper({'fs','dynrange'},definput,varargin);

% Downsample
if ~isempty(kv.fmax)
  if ~isempty(fs)
    resamp=kv.fmax*2/fs;
  else
    resamp=kv.fmax*2/length(f);
  end;

  f=fftresample(f,round(length(f)*resamp));
  kv.fs=2*kv.fmax;
end;

Ls=length(f);

if flags.do_posfreq
   kv.yres=2*kv.yres;
end;

try
  [a,M,L,N,Ndisp]=gabimagepars(Ls,kv.xres,kv.yres);
catch
  err=lasterror;
  if strcmp(err.identifier,'LTFAT:noframe')
    error(sprintf(['The signal is too long. SGRAM cannot visualize all the details.\n' ...
                   'Try a shorter signal or increase the image resolution by calling:\n\n' ...
                   '  sgram(...,''xres'',xres,''yres'',yres);\n\n' ...
                   'for larger values of xres and yres.\n'...
                   'The current values are:\n  xres=%i\n  yres=%i'],kv.xres,kv.yres));
  else
    rethrow(err);
  end;
end;

% Set an explicit window length, if this was specified.
if flags.do_wlen
  kv.tfr=kv.wlen^2/L;
end;

g={'gauss',kv.tfr,flags.norm};

if flags.do_nf
  coef=abs(dgt(f,g,a,M));
else
  coef=abs(dgtreal(f,g,a,M));
end;

% Cut away zero-extension.
coef=coef(:,1:Ndisp);

if flags.do_thr
  % keep only the largest coefficients.
  coef=largestr(coef,kv.thr);
end

if flags.do_nf
  coef=plotdgt(coef,a,'argimport',flags,kv);
else
  coef=plotdgtreal(coef,a,M,'argimport',flags,kv);
end;

if nargout>0
  varargout={coef};
end;

