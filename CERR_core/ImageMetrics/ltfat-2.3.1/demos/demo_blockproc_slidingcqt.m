function demo_blockproc_slidingcqt(source,varargin) 
%-*- texinfo -*-
%@deftypefn {Function} demo_blockproc_slidingcqt
%@verbatim
%DEMO_BLOCKPROC_SLIDINGCQT Basic real-time rolling CQT-spectrogram visualization
%   Usage: demo_blockproc_slidingcqt('gspi.wav')
%
%   For additional help call DEMO_BLOCKPROC_SLIDINGCQT without arguments.
%
%   This demo shows a simple rolling CQT-spectrogram of whatever is specified in
%   source. 
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_blockproc_slidingcqt.html}
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

if demo_blockproc_header(mfilename,nargin)
   return;
end

% Control pannel (Java object)
% Each entry determines one parameter to be changed during the main loop
% execution.
p = blockpanel({
               {'GdB','Gain',-20,20,0,21},...
               {'cMult','C mult',-40,40,10,41}
               });
           
fobj = blockfigure();
    
% Buffer length
% Larger the number the higher the processing delay. 1024 with fs=44100Hz
% makes ~23ms.
% Note that the processing itself can introduce additional delay.



% Setup blocktream
try
   fs=block(source,varargin{:},'loadind',p);
catch
    % Close the windows if initialization fails
    blockdone(p,fobj);
    err = lasterror;
    error(err.message);
end

% Buffer length (30 ms)
bufLen = floor(30e-3*fs);
zpad = floor(bufLen/2);

% Prepare CQT filters in range floor(fs/220),floor(fs/2.2) Hz, 
% 48 bins per octave
% 320 + 2 filters in total (for fs = 44100 Hz).
% And a frame object representing the filterbank
F = frame('cqtfb',fs,floor(fs/220),floor(fs/2.2),48,2*bufLen+2*zpad,'fractionaluniform');
% Accelerate the frame object to be used with the "sliced" block processing
% handling.
Fa = blockframeaccel(F,bufLen,'sliced','zpad',zpad);

% This variable holds overlaps in coefficients needed in the sliced block
% handling between consecutive loop iterations.
cola = [];
flag = 1;
%Loop until end of the stream (flag) and until panel is opened
while flag && p.flag
  % Get parameters 
  [gain, mult] = blockpanelget(p,'GdB','cMult');
  % Overal gain of the input
  gain = 10^(gain/20);
  % Coefficient magnitude mult. factor
  % Introduced to make coefficients to tune
  % the coefficients to fit into dB range used by
  % blockplot.
  mult = 10^(mult/20);

  % Read block of length bufLen
  [f,flag] = blockread(bufLen);
  f = f*gain;
  % Apply analysis frame
  c = blockana(Fa, f); 
  % Append coefficients to plot  
  cola = blockplot(fobj,Fa,mult*c(:,1),cola);
  % Play the samples
  blockplay(f);
end

% Close the stream, destroy the objects
blockdone(p,Fa,fobj);




