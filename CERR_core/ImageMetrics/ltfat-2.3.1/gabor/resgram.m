function varargout=resgram(f,varargin)
%-*- texinfo -*-
%@deftypefn {Function} resgram
%@verbatim
%RESGRAM  Reassigned spectrogram plot
%   Usage: resgram(f,op1,op2, ... );
%          resgram(f,fs,op1,op2, ... );
%
%   RESGRAM(f) plots a reassigned spectrogram of f.
%
%   RESGRAM(f,fs) does the same for a signal with sampling rate fs*
%   (sampled with fs samples per second).
%
%   Because reassigned spectrograms can have an extreme dynamical range,
%   consider always using the 'dynrange' or 'clim' options (see below)
%   in conjunction with the 'db' option (on by default). An example:
%
%     resgram(greasy,16000,'dynrange',70);
%
%   This will produce a reassigned spectrogram of the GREASY signal
%   without drowning the interesting features in noise.
%
%   C=RESGRAM(f, ... ) returns the image to be displayed as a matrix. Use this
%   in conjunction with imwrite etc. These coefficients are *only* intended to
%   be used by post-processing image tools. Reassignment should be done
%   using the GABREASSIGN function instead.
%
%   RESGRAM accepts the following additional arguments:
%
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
%     'sharp',alpha
%                  Set the sharpness of the plot. If alpha=0 the regular
%                  spectrogram is obtained. alpha=1 means full
%                  reassignment. Anything in between will produce a partially
%                  sharpened picture. Default is alpha=1.
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
%                  The default value is 600
%    
%     'contour'    Do a contour plot to display the spectrogram.
%           
%     'surf'       Do a surf plot to display the spectrogram.
%    
%     'mesh'       Do a mesh plot to display the spectrogram.
%    
%     'colorbar'   Display the colorbar. This is the default.
%    
%     'nocolorbar'  Do not display the colorbar.
%
%   In addition to these parameters, sgram accepts any of the flags from
%   NORMALIZE. The window used to calculate the spectrogram will be
%   normalized as specified.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/resgram.html}
%@seealso{sgram}
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

% BUG: Setting the sharpness different from 1 produces a black line in the
% middle of the plot.
  
if nargin<1
  error('Too few input arguments.');
end;

if sum(size(f)>1)>1
  error('Input must be a vector.');
end;

definput.import={'ltfattranslate','normalize','tfplot'};

% Define initial value for flags and key/value pairs.
definput.flags.wlen={'nowlen','wlen'};
definput.flags.thr={'nothr','thr'};
definput.flags.tc={'notc','tc'};
definput.flags.plottype={'image','contour','mesh','pcolor'};

% Override the setting from tfplot, because SGRAM does not support the
% 'dbsq' setting (it does not make sense).
definput.flags.log={'db','lin'};


if isreal(f)
  definput.flags.posfreq={'posfreq','nf'};
else
  definput.flags.posfreq={'nf','posfreq'};
end;

definput.keyvals.sharp=1;
definput.keyvals.tfr=1;
definput.keyvals.wlen=0;
definput.keyvals.thr=0;
definput.keyvals.fmax=[];
definput.keyvals.xres=800;
definput.keyvals.yres=600;

[flags,kv,fs]=ltfatarghelper({'fs','dynrange'},definput,varargin);

if (kv.sharp<0 || kv.sharp >1)
  error(['RESGRAM: Sharpness parameter must be between (including) ' ...
	 '0 and 1']);
end;

% Downsample
if ~isempty(kv.fmax)
  if ~isempty(kv.fs)
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
    error(sprintf(['The signal is too long. RESGRAM cannot visualize all the details.\n' ...
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

[tgrad,fgrad,c]=gabphasegrad('dgt',f,g,a,M);          
coef=gabreassign(abs(c).^2,kv.sharp*tgrad,kv.sharp*fgrad,a);

% Cut away zero-extension.
coef=coef(:,1:Ndisp);

if flags.do_thr
  % keep only the largest coefficients.
  coef=largestr(coef,kv.thr);
end

if flags.do_posfreq
  coef=coef(1:floor(M/2)+1,:);
  plotdgtreal(coef,a,M,'argimport',flags,kv);
else
  plotdgt(coef,a,'argimport',flags,kv);
end;


if nargout>0
  varargout={coef};
end;

