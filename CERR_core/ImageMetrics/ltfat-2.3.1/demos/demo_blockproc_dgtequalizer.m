function demo_blockproc_dgtequalizer(source,varargin) 
%-*- texinfo -*-
%@deftypefn {Function} demo_blockproc_dgtequalizer
%@verbatim
%DEMO_BLOCKPROC_DGTEQUALIZER Real-time audio manipulation in the transform domain
%   Usage: demo_blockproc_dgtequalizer('gspi.wav')
%
%   For additional help call DEMO_BLOCKPROC_DGTEQUALIZER without arguments.
%
%   This script demonstrates a real-time Gabor coefficient manipulation.
%   Frequency bands of Gabor coefficients are multiplied (weighted) by
%   values taken from sliders having a similar effect as a octave equalizer.
%   The shown spectrogram is a result of a re-analysis of the synthetized 
%   block to show a frequency content of what is actually played. 
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_blockproc_dgtequalizer.html}
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

M = 1000;

fobj = blockfigure();
            
octaves = 6;
voices = 1;
eqbands = (octaves)*voices;

d = floor((floor(M/2)+1)*2.^(-(0:eqbands-1)./(voices)));
d = fliplr([d,0]); 

% Basic Control pannel (Java object)
parg = {{'GdB','Gain',-20,20,0,21}};
for ii=1:eqbands
   parg{end+1} = {sprintf('G%idB',ii),sprintf('band%i',ii),-20,20,0,21};
end

p = blockpanel(parg);
    


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

% Window length in ms
winLenms = 20; %floor(fs*winLenms/1e3)
[F,Fdual] = framepair('dgtreal',{'hann',floor(fs*winLenms/1e3)},'dual',40,M);
[Fa,Fs] = blockframepairaccel(F,Fdual, bufLen,'segola');

flag = 1;
ola = [];
ola2 = [];
%Loop until end of the stream (flag) and until panel is opened
while flag && p.flag
   gain = blockpanelget(p);
   gain = 10.^(gain/20);

   [f,flag] = blockread(bufLen);
   f=f*gain(1);
   gain = gain(2:end);
   
   [c, ola] = blockana(Fa, f, ola);
   
   cc = framecoef2tf(Fa,c);
   % Do the weighting
   for ii=1:eqbands
      cc(d(ii)+1:d(ii+1),:,:) = gain(ii)*cc(d(ii)+1:d(ii+1),:,:);
   end
   c = frametf2coef(Fa,cc);
   
   fhat = blocksyn(Fs, c, size(f,1));
   
   
   blockplay(fhat);
   
   % Do re-analysis of the modified
   [c2, ola2] = blockana(Fa, fhat, ola2);
   blockplot(fobj,Fa,c2(:,1));
end
blockdone(p,fobj);


