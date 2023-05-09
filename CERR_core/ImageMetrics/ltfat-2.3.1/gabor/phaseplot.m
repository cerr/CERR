function varargout=phaseplot(f,varargin)
%-*- texinfo -*-
%@deftypefn {Function} phaseplot
%@verbatim
%PHASEPLOT  Phase plot
%   Usage: phaseplot(f,op1,op2, ... );
%          phaseplot(f,fs,op1,op2, ... );
%
%   PHASEPLOT(f) plots the phase of f using a DGT.
%
%   PHASEPLOT(f,fs) does the same for a signal with sampling rate fs Hz.
%
%   PHASEPLOT should only be used for short signals (shorter than the
%   resolution of the screen), as there will otherwise be some visual
%   aliasing, such that very fast changing areas will look very smooth.
%   PHASEPLOT always calculates the phase of the full time/frequency plane
%   (as opposed to SGRAM), and you therefore risk running out of memory
%   for long signals.
%
%   PHASEPLOT takes the following flags at the end of the line of input
%   arguments:
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
%     'nf'        Display negative frequencies, with the zero-frequency
%                 centered in the middle. For real signals, this will just
%                 mirror the upper half plane. This is standard for complex
%                 signals.
%  
%     'tc'        Time centering. Move the beginning of the signal to the
%                 middle of the plot. This is usefull for visualizing the
%                 window functions of the toolbox.
%  
%     'thr',r     Keep the coefficients with a magnitude larger than r times the
%                 largest magnitude. Set the phase of the rest of the
%                 coefficients to zero. This is useful, because for small
%                 amplitude the phase values can be meaningless.
%  
%     'timeinv'   Display the phase as computed by a time-invariant
%                 DGT. This is the default.
%  
%     'freqinv'   Display the phase as computed by a frequency-invariant
%                 DGT.
%  
%     'fmax',y    Display y as the highest frequency.
%
%     'colorbar'   Display the colorbar. This is the default.
%    
%     'nocolorbar'  Do not display the colorbar.
%
%   For the best result when using PHASEPLOT, use a circulant color
%   map, for instance hsv.
%
%   Examples:
%   ---------
%
%   The following code shows the phaseplot of a
%   periodic, hyperbolic secant visualized using the hsv colormap:
%
%     phaseplot(psech(200),'tc','nf');
%     colormap(hsv);
%
%   The following phaseplot shows the phase of white, Gaussian noise:
%
%     phaseplot(randn(200,1));
%     colormap(hsv);
% 
%
%
%   References:
%     R. Carmona, W. Hwang, and B. Torresani. Practical Time-Frequency
%     Analysis: continuous wavelet and Gabor transforms, with an
%     implementation in S, volume 9 of Wavelet Analysis and its Applications.
%     Academic Press, San Diego, 1998.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/phaseplot.html}
%@seealso{phaselock, demo_phaseplot}
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
%   TESTING: NA

if nargin<1
  error('Too few input arguments.');
end;

if sum(size(f)>1)>1
  error('Input must be a vector.');
end;

definput.import={'ltfattranslate','normalize','tfplot'};
% Override the setting from tfplot, because phaseplot only uses the 'lin'
% plotting.
definput.flags.log={'lin'};
definput.importdefaults={'lin'};

% Define initial value for flags and key/value pairs.
definput.flags.wlen={'nowlen','wlen'};
definput.flags.tc={'notc','tc'};

definput.flags.fmax={'nofmax','fmax'};
definput.flags.phase={'timeinv','freqinv'};

if isreal(f)
  definput.flags.posfreq={'posfreq','nf'};
else
  definput.flags.posfreq={'nf','posfreq'};
end;

definput.keyvals.tfr=1;
definput.keyvals.wlen=0;
definput.keyvals.fmax=[];
definput.keyvals.thr=[];

[flags,kv,fs]=ltfatarghelper({'fs'},definput,varargin);

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

% Always do the full STFT
L=length(f);
a=1;
b=1;
M=L;
N=L;

% Set an explicit window length, if this was specified.
if flags.do_wlen
  kv.tfr=kv.wlen^2/L;
end;

g={'gauss',kv.tfr,flags.norm};

if flags.do_nf
  coef=dgt(f,g,a,M,flags.phase);
else
  coef=dgtreal(f,g,a,M,flags.phase);
end;

if ~isempty(kv.thr)
  % keep only the largest coefficients.
  maxc=max(abs(coef(:)));
  mask=abs(coef)<maxc*kv.thr;
  coef(mask)=0;
end

coef = angle(coef);

if flags.do_nf
  plotdgt(coef,a,'argimport',flags,kv);
else
  plotdgtreal(coef,a,M,'argimport',flags,kv);
end;

if nargout>0
  varargout={coef};
end;

