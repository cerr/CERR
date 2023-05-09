function [g,info]=firwin(name,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} firwin
%@verbatim
%FIRWIN  FIR window
%   Usage:  g=firwin(name,M);
%           g=firwin(name,M,...);
%           g=firwin(name,x);
%           
%   FIRWIN(name,M) will return an FIR window of length M of type name.
%
%   All windows are symmetric and generate zero delay and zero phase
%   filters. They can be used for the Wilson and WMDCT transform, except
%   when noted otherwise.
%
%   FIRWIN(name,x) where x is a vector will sample the window
%   definition as the specified points. The normal sampling interval for
%   the windows is -.5< x <.5.
%
%   In the following PSL means "Peak Sidelobe level", and the main lobe
%   width is measured in normalized frequencies.
%
%   If a window g forms a "partition of unity" (PU) it means specifically
%   that:
%
%     g+fftshift(g)==ones(L,1);
%
%   A PU can only be formed if the window length is even, but some windows
%   may work for odd lengths anyway.
%
%   If a window is the square root of a window that forms a PU, the window
%   will generate a tight Gabor frame / orthonormal Wilson/WMDCT basis if
%   the number of channels is less than M.
%
%   The windows available are:
%
%     'hann'       von Hann window. Forms a PU. The Hann window has a
%                  mainlobe with of 8/M, a PSL of -31.5 dB and decay rate
%                  of 18 dB/Octave.
%
%     'sine'       Sine window. This is the square root of the Hanning
%                  window. The sine window has a mainlobe width of 8/M,
%                  a  PSL of -22.3 dB and decay rate of 12 dB/Octave.
%                  Aliases: 'cosine', 'sqrthann'
%
%     'rect'       (Almost) rectangular window. The rectangular window has a
%                  mainlobe width of 4/M, a PSL of -13.3 dB and decay
%                  rate of 6 dB/Octave. Forms a PU if the order is odd.
%                  Alias: 'square'
%
%     'tria'       (Almost) triangular window. Forms a PU. Alias: 'bartlett'
%
%     'sqrttria'   Square root of the triangular window.
%
%     'hamming'    Hamming window. Forms a PU that sums to 1.08 instead
%                  of 1.0 as usual. The Hamming window has a
%                  mainlobe width of 8/M, a  PSL of -42.7 dB and decay
%                  rate of 6 dB/Octave. This window should not be used for
%                  a Wilson basis, as a reconstruction window cannot be
%                  found by WILDUAL.
%
%     'blackman'   Blackman window. The Blackman window has a
%                  mainlobe width of 12/M, a PSL of -58.1 dB and decay
%                  rate of 18 dB/Octave.
%
%     'blackman2'  Alternate Blackman window. This window has a
%                  mainlobe width of 12/M, a PSL of -68.24 dB and decay
%                  rate of 6 dB/Octave.
%
%     'itersine'   Iterated sine window. Generates an orthonormal
%                  Wilson/WMDCT basis. This window is described in 
%                  Wesfreid and Wickerhauser (1993) and is used in  the
%                  ogg sound codec. Alias: 'ogg'
%
%     'nuttall'    Nuttall window. The Nuttall window has a
%                  mainlobe width of 16/M, a PSL of -93.32 dB and decay
%                  rate of 18 dB/Octave.
%
%     'nuttall10'  2-term Nuttall window with 1 continuous derivative. 
%                  Alias: 'hann', 'hanning'.
%
%     'nuttall01'  2-term Nuttall window with 0 continuous derivatives. 
%                  This is a slightly improved Hamming window. It has a
%                  mainlobe width of 8/M, a  PSL of -43.19 dB and decay
%                  rate of 6 dB/Octave.
%
%     'nuttall20'  3-term Nuttall window with 3 continuous derivatives. 
%                  The window has a mainlobe width of 12/M, a PSL of 
%                  -46.74 dB and decay rate of 30 dB/Octave.
%
%     'nuttall11'  3-term Nuttall window with 1 continuous derivative. 
%                  The window has a mainlobe width of 12/M, a PSL of 
%                  -64.19 dB and decay rate of 18 dB/Octave.
%
%     'nuttall02'  3-term Nuttall window with 0 continuous derivatives. 
%                  The window has a mainlobe width of 12/M, a PSL of 
%                  -71.48 dB and decay rate of 6 dB/Octave.
%
%     'nuttall30'  4-term Nuttall window with 5 continuous derivatives. 
%                  The window has a mainlobe width of 16/M, a PSL of 
%                  -60.95 dB and decay rate of 42 dB/Octave.
%
%     'nuttall21'  4-term Nuttall window with 3 continuous derivatives. 
%                  The window has a mainlobe width of 16/M, a PSL of 
%                  -82.60 dB and decay rate of 30 dB/Octave.
%
%     'nuttall12'  4-term Nuttall window with 1 continuous derivatives. 
%                  Alias: 'nuttall'.
%
%     'nuttall03'  4-term Nuttall window with 0 continuous derivatives. 
%                  The window has a mainlobe width of 16/M, a PSL of 
%                  -98.17 dB and decay rate of 6 dB/Octave.
%
%     'truncgauss' Gaussian window truncated at 1% of its height.
%                  Alternatively, a custom percentage can be appended to
%                  'truncgauss' e.g. 'truncgauss0.1' will create Gaussian
%                  window truncated at 0.1% of its height.
%
%   FIRWIN understands the following flags at the end of the list of input
%   parameters:
%
%     'shift',s    Shift the window by s samples. The value can be a
%                  fractional number.
%
%     'wp'         Output is whole point even. This is the default. It
%                  corresponds to a shift of s=0.
%
%     'hp'         Output is half point even, as most Matlab filter
%                  routines. This corresponds to a shift of s=-.5
%                   
%
%     'taper',t    Extend the window by a flat section in the middle. The
%                  argument t is the ratio of the rising and falling
%                  parts as compared to the total length of the
%                  window. The default value of 1 means no
%                  tapering. Accepted values lie in the range from 0 to 1.
%
%   Additionally, FIRWIN accepts flags to normalize the output. Please see
%   the help of NORMALIZE. Default is to use 'peak' normalization,
%   which is useful for using the output from FIRWIN for windowing in the
%   time-domain. For filtering in the time-domain, a normalization of '1'
%   or 'area' is preferable.
%
%   Examples:
%   ---------
%
%   The following plot shows the magnitude response for some common
%   windows:
%
%     hold all; 
%     L=30;
%     dr=110;
%
%     magresp(firwin('hanning',L,'1'),'fir','dynrange',dr);
%     magresp(firwin('hamming',L,'1'),'fir','dynrange',dr);
%     magresp(firwin('blackman',L,'1'),'fir','dynrange',dr);
%     magresp(firwin('nuttall',L,'1'),'fir','dynrange',dr);
%     magresp(firwin('itersine',L,'1'),'fir','dynrange',dr);
%
%     legend('Hann','Hamming','Blackman','Nuttall','Itersine');
%
%
%   References:
%     A. V. Oppenheim and R. W. Schafer. Discrete-time signal processing.
%     Prentice Hall, Englewood Cliffs, NJ, 1989.
%     
%     A. Nuttall. Some windows with very good sidelobe behavior. IEEE Trans.
%     Acoust. Speech Signal Process., 29(1):84--91, 1981.
%     
%     F. Harris. On the use of windows for harmonic analysis with the
%     discrete Fourier transform. Proceedings of the IEEE, 66(1):51 -- 83,
%     jan 1978.
%     
%     E. Wesfreid and M. Wickerhauser. Adapted local trigonometric transforms
%     and speech processing. IEEE Trans. Signal Process., 41(12):3596--3600,
%     1993.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/firwin.html}
%@seealso{freqwin, pgauss, pbspline, firkaiser, normalize}
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
 
%   AUTHORS : Peter L. Soendergaard, Nicki Holighaus.
%   REFERENCE: NA
  
if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end

if ~ischar(name)
  error('%s: First input argument must the name of a window.',...
        upper(mfilename));
end

if ~isnumeric(M)
  error('%s: M must be numeric.',upper(mfilename));  
end

% Always set to this
info.isfir=1;

% Default values, may be overwritten later in the code
info.ispu=0;
info.issqpu=0;

name=lower(name);

% Define initial value for flags and key/value pairs.
definput.import={'normalize'};
definput.importdefaults={'null'};
definput.flags.centering={'wp','hp','shift'};
definput.keyvals.shift=0;

definput.keyvals.taper=1;

[flags,kv]=ltfatarghelper({},definput,varargin);

if flags.do_wp
  kv.shift=0;
end;

if flags.do_hp
  kv.shift=0.5;
end;

if M==0
  g=[];
  return;
end;

if numel(M)==1
    complainif_notposint(M,'M',mfilename);
    
    % Deal with tapering
    if kv.taper<1
        if kv.taper==0
            % Window is only tapering, do this and bail out, because subsequent
            % code may fail.
            g=ones(M,1);
            return;
        end;
        
        % Modify M to fit with tapering
        Morig=M;
        M=round(M*kv.taper);
        Mtaper=Morig-M;
        
        p1=round(Mtaper/2);
        p2=Mtaper-p1;
        
        % Switch centering if necessary
        if flags.do_wp && p1~=p2
            kv.shift=.5;
        end;
        
        if flags.do_hp && p1~=p2
            kv.shift=1;
        end;
        
    end;
    
    % This is the normally used sampling vector.
    
    if mod(M,2) == 0 % For even M the sampling interval is [-.5,.5-1/M]
        x = [0:1/M:.5-1/M,-.5:1/M:-1/M]';
    else % For odd M the sampling interval is [-.5+1/(2M),.5-1/(2M)]
        x = [0:1/M:.5-.5/M,-.5+.5/M:1/M:-1/M]';
    end
    
    x = x+kv.shift/M;
    
else
    % Use sampling vector specified by the user
    x=M;
end;

startswith = 'truncgauss';
if regexpi(name,['^',startswith])
     percent = 1;
     if numel(name) > numel(startswith)
            suffix = name(numel(startswith)+1:end);
            percent = str2double(suffix);
            if isnan(percent)
                error('%s: Passed "%s" and "%s" cannot be parsed to a number.',...
                      upper(mfilename),name,suffix);
            end
     end
     name = startswith;
end

do_sqrt=0;
switch name    
 case {'hanning','hann','nuttall10'}
  g=(0.5+0.5*cos(2*pi*x));
  info.ispu=1;
  
 case {'sine','cosine','sqrthann'}
  g=firwin('hanning',M,varargin{:});
  info.issqpu=1;
  do_sqrt=1;
  
 case 'hamming'
  g=0.54+0.46*cos(2*pi*(x));

  % This is the definition taken from the Harris paper
  %case 'hammingacc'
  %g=25/46+21/46*cos(2*pi*(x));

 case 'nuttall01'
  g=0.53836+0.46164*cos(2*pi*(x));

 case {'square','rect'} 
  g=double(abs(x) < .5);
  
 case {'tria','triangular','bartlett'}
  g=1-2*abs(x);
  info.ispu=1;
  
 case {'sqrttria'}
  g=firwin('tria',M,flags.centering);
  info.issqpu=1;
  do_sqrt=1;

  % Rounded version of blackman2
 case {'blackman'}
  g=0.42+0.5*cos(2*pi*(x))+0.08*cos(4*pi*(x));

 case {'blackman2'}
  g=7938/18608+9240/18608*cos(2*pi*(x))+1430/18608*cos(4*pi*(x));

 case {'nuttall','nuttall12'}
  g = 0.355768+0.487396*cos(2*pi*(x))+0.144232*cos(4*pi*(x)) ...
      +0.012604*cos(6*pi*(x));
  
 case {'itersine','ogg'}
  g=sin(pi/2*cos(pi*x).^2);
  info.issqpu=1;
  
 case {'nuttall20'}
  g=3/8+4/8*cos(2*pi*(x))+1/8*cos(4*pi*(x));

 case {'nuttall11'}
  g=0.40897+0.5*cos(2*pi*(x))+0.09103*cos(4*pi*(x));
  
 case {'nuttall02'}
   g=0.4243801+0.4973406*cos(2*pi*(x))+0.0782793*cos(4*pi*(x));
   
 case {'nuttall30'}
  g = 10/32+15/32*cos(2*pi*(x))+6/32*cos(4*pi*(x))+1/32*cos(6*pi*(x));
  
 case {'nuttall21'}
  g = 0.338946+0.481973*cos(2*pi*(x))+0.161054*cos(4*pi*(x)) ... 
      +0.018027*cos(6*pi*(x));

 case {'nuttall03'}
  g=0.3635819+0.4891775*cos(2*pi*(x))+0.1365995*cos(4*pi*(x)) ...
      +0.0106411*cos(6*pi*(x));
 
 case {'truncgauss'}
  g = exp(4*log(percent/100)*x.^2);
  
 otherwise
  error('Unknown window: %s.',name);
end;

% Force the window to 0 outside (-.5,.5)
g = g.*(abs(x) < .5);    

if numel(M) == 1 && kv.taper<1

    % Perform the actual tapering.
    g=[ones(p1,1);g;ones(p2,1)];  
    
end;   

% Do sqrt if needed. 
if do_sqrt
  g=sqrt(g);
end;

g=normalize(g,flags.norm);


