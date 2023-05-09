function varargout=instfreqplot(f,varargin)
%-*- texinfo -*-
%@deftypefn {Function} instfreqplot
%@verbatim
%INSTFREQPLOT  Plot of instantaneous frequency
%   Usage: instfreqplot(f,op1,op2, ... );
%          instfreqplot(f,fs,op1,op2, ... );
%
%   INSTFREQPLOT(f) plots the instantaneous frequency of f using a DGT.
%
%   INSTFREQPLOT(f,fs) does the same for a signal with sampling rate
%   fs Hz.
%
%   The instantaneous frequency contains extreme spikes in regions
%   where the spectrogram is close to zero. These points are usually
%   uninteresting and destroy the visibility of the plot. Use the 'thr'
%   or 'clim' or 'climsym' options (see below) to remove these points.
%
%   An example:
%
%     instfreqplot(greasy,16000,'thr',.03,'climsym',100);
%
%   will produce a nice instantaneous frequency plot of the GREASY
%   signal.
%
%   INSTFREQPLOT accepts the following optional arguments:
%
%     'tfr',v     Set the ratio of frequency resolution to time resolution.
%                 A value v=1 is the default. Setting v>1 will give better
%                 frequency resolution at the expense of a worse time
%                 resolution. A value of 0<v<1 will do the opposite.
%  
%     'wlen',s    Window length. Specifies the length of the window
%                 measured in samples. See help of PGAUSS on the exact
%                 details of the window length.
%  
%     'thr',r     Keep the coefficients with a magnitude larger than r*
%                 times the largest magnitude. Set the instantaneous 
%                 frequency of the rest of the coefficients to zero
%  
%     'nf'        Display negative frequencies, with the zero-frequency
%                 centered in the middle. For real signals, this will just
%                 mirror the upper half plane. This is standard for complex
%                 signals.
%  
%     'tc'        Time centering. Move the beginning of the signal to the
%                 middle of the plot. This is useful for visualizing the
%                 window functions of the toolbox.
%  
%     'image'     Use imagesc to display the spectrogram. This is the
%                 default.
%  
%     'dgt'       Use the 'dgt' method to compute the instantaneous
%                 frequency. This is the default.
%  
%     'clim',clim  Use a colormap ranging from clim(1) to clim(2). These
%                  values are passed to imagesc. See the help on imagesc.
%  
%     'climsym',cval  Use a colormap ranging from -cval to cval
%  
%     'fmax',y    Display y as the highest frequency.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/instfreqplot.html}
%@seealso{sgram, resgram, phaseplot}
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
%   REFERENCE: NA
%   TESTING: NA
  
if nargin<1
  error('Too few input arguments.');
end;

if sum(size(f)>1)>1
  error('Input must be a vector.');
end;

% Define initial value for flags and key/value pairs.
definput.flags.wlen={'nowlen','wlen'};
definput.flags.tc={'notc','tc'};
definput.flags.method={'dgt','phase','abs'};
definput.flags.clim={'noclim','clim','climsym'};

if isreal(f)
  definput.flags.posfreq={'posfreq','nf'};
else
  definput.flags.posfreq={'nf','posfreq'};
end;

definput.keyvals.tfr=1;
definput.keyvals.wlen=0;
definput.keyvals.thr=[];
definput.keyvals.clim=[0,1];
definput.keyvals.climsym=1;
definput.keyvals.fmax=[];
definput.keyvals.xres=800;
definput.keyvals.yres=600;
definput.keyvals.fs=[];
[flags,kv,fs]=ltfatarghelper({'fs'},definput,varargin);

% Override the setting from tfplot, because INSTFREQPLOT does not support the
% dB-settings
flags.do_lin=1;
flags.do_db=0;
flags.do_dbsq=0;

dofs=~isempty(fs);

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
    error(sprintf(['The signal is too long. INSTFREQPLOT cannot visualize all the details.\n' ...
                   'Try a shorter signal or increase the image resolution by calling:\n\n' ...
                   '  sgram(...,''xres'',xres,''yres'',yres);\n\n' ...
                   'for larger values of xres and yres.\n'...
                   'The current values are:\n  xres=%i\n  yres=%i'],kv.xres,kv.yres));
  else
    rethrow(err);
  end;
end;


b=L/N;

% Set an explicit window length, if this was specified.
if flags.do_wlen
  kv.tfr=kv.wlen^2/L;
end;

g={'gauss',kv.tfr};

if flags.do_dgt
  [coef,fgrad,dgtcoef]=gabphasegrad('dgt',f,g,a,M);
end;

if flags.do_phase
  dgtcoef=dgt(f,g,a,M);
  [coef,fgrad]=gabphasegrad('phase',angle(dgtcoef),a);
end;

if flags.do_abs  
  dgtcoef=dgt(f,g,a,M);
  [coef,fgrad]=gabphasegrad('abs',abs(dgtcoef),g,a);
end;

if ~isempty(kv.thr)
  % keep only the largest coefficients.
  maxc=max(abs(dgtcoef(:)));
  mask=abs(dgtcoef)<maxc*kv.thr;

  coef(mask)=0;
end

% Cut away zero-extension.
coef=coef(:,1:Ndisp);

% Convert climsym into a normal clim
if flags.do_climsym
  flags.do_clim=1;
  kv.clim=[-kv.climsym,kv.climsym];
end;

if flags.do_posfreq
  coef=coef(1:floor(M/2)+1,:);
  plotdgtreal(coef,a,M,'argimport',flags,kv);
else
  plotdgt(coef,a,'argimport',flags,kv);
end;

if nargout>0
  varargout={coef};
end;

