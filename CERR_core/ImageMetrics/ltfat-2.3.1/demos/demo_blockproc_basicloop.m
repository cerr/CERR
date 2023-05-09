function demo_blockproc_basicloop(source,varargin) 
%-*- texinfo -*-
%@deftypefn {Function} demo_blockproc_basicloop
%@verbatim
%DEMO_BLOCKPROC_BASICLOOP Basic real-time audio manipulation
%   Usage: demo_blockproc_basicloop('gspi.wav')
%
%   For additional help call DEMO_BLOCKPROC_BASICLOOP without arguments.
%
%   The demo runs simple playback loop allowing to set gain in dB.
% 
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_blockproc_basicloop.html}
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



% Basic Control pannel (Java object)
p = blockpanel({
               {'GdB','Gain',-20,20,0,21},...
               });


           
% Setup blocktream
try
    fs = block(source,varargin{:},'loadind',p);
catch
    % Close the windows if initialization fails
    blockdone(p);
    err = lasterror;
    error(err.message);
end

% Set buffer length to 30 ms
L = floor(30e-3*fs);

flag = 1;
%Loop until end of the stream (flag) and until panel is opened
while flag && p.flag
   gain = blockpanelget(p,'GdB');
   gain = 10^(gain/20);
   
   [f,flag] = blockread(L);
   % The following does nothing in the rec only mode.
   blockplay(f*gain);
   % The following does nothing if 'outfile' was not specified 
   blockwrite(f);
end
blockdone(p);

