function demo_blockproc_slidingerblets(source,varargin) 
%-*- texinfo -*-
%@deftypefn {Function} demo_blockproc_slidingerblets
%@verbatim
%DEMO_BLOCKPROC_SLIDINGERBLETS Basic real-time rolling erblet-spectrogram visualization
%   Usage: demo_blockproc_slidingerblets('gspi.wav')
%
%   For additional help call DEMO_BLOCKPROC_SLIDINGERBLETS without arguments.
%
%   This demo shows a simple rolling erblet-spectrogram of whatever is specified in
%   source. 
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_blockproc_slidingerblets.html}
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
               {'cMult','C mult',0,80,20,81}
               });
            
fobj = blockfigure();

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

% Number of filters
M = 200;
F = frame('erbletfb',fs,2*bufLen+2*zpad,'fractionaluniform','M',M);
Fa = blockframeaccel(F,bufLen,'sliced','zpad',zpad);

flag = 1;
cola = [];
%Loop until end of the stream (flag) and until panel is opened
while flag && p.flag
  % Get parameters 
  [gain,mult] = blockpanelget(p,'GdB','cMult');
  gain = 10^(gain/20);
  mult = 10^(mult/20);

  % Read block of length bufLen
  [f,flag] = blockread(bufLen);
  f = f*gain;
  % Apply analysis frame
  c = blockana(Fa, f); 
  % Plot
  cola = blockplot(fobj,Fa,mult*c(:,1),cola);
  
  blockplay(f);
end
blockdone(p,fobj,Fa);




