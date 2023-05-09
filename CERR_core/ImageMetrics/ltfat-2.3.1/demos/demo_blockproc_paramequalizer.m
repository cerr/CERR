function demo_blockproc_paramequalizer(source,varargin) 
%-*- texinfo -*-
%@deftypefn {Function} demo_blockproc_paramequalizer
%@verbatim
%DEMO_BLOCKPROC_PARAMEQUALIZER Real-time equalizer demonstration
%   Usage: demo_blockproc_paramequalizer('gspi.wav')
%
%   For additional help call DEMO_BLOCKPROC_PARAMEQUALIZER without arguments.
%
%   This demonstration shows an example of a octave parametric
%   equalizer. See chapter 5.2 in the book by Zolzer.
% 
%   References:
%     U. Zolzer. Digital Audio Signal Processing. John Wiley and Sons Ltd, 2
%     edition, 2008.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_blockproc_paramequalizer.html}
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

% Buffer length
% Larger the number the higher the processing delay. 1024 with fs=44100Hz
% makes ~23ms.
% The value can be any positive integer.
% Note that the processing itself can introduce additional delay.

% Quality parameter of the peaking filters
Q = sqrt(2);

% Filters 
filts = [
         struct('Hb',[1;0],'Ha',[1;0],'G',0,'Z',[0;0],'type','lsf'),...
         struct('Hb',[1;0;0],'Ha',[1;0;0],'G',0,'Z',[0;0],'type','peak'),...
         struct('Hb',[1;0;0],'Ha',[1;0;0],'G',0,'Z',[0;0],'type','peak'),...
         struct('Hb',[1;0;0],'Ha',[1;0;0],'G',0,'Z',[0;0],'type','peak'),...
         struct('Hb',[1;0;0],'Ha',[1;0;0],'G',0,'Z',[0;0],'type','peak'),...
         struct('Hb',[1;0;0],'Ha',[1;0;0],'G',0,'Z',[0;0],'type','hsf')...
        ];
     
     
% Control pannel (Java object)
% Each entry determines one parameter to be changed during the main loop
% execution.

pcell = cell(1,numel(filts));
for ii=1:numel(filts)
   pcell{ii} =  {sprintf('band%i',ii),'Gain',-10,10,filts(ii).G,41};
end
p = blockpanel(pcell); 

% Setup blocktream
try
    fs = block(source,varargin{:},'loadind',p);
catch
    % Close the windows if initialization fails
    blockdone(p);
    err = lasterror;
    error(err.message);
end

% Buffer length (30 ms)
bufLen = floor(30e-3*fs);

% Cutoff/center frequency
feq = [0.0060, 0.0156, 0.0313, 0.0625, 0.1250, 0.2600]*fs;

% Build the filters
[filts(1).Ha, filts(1).Hb] = parlsf(feq(1),blockpanelget(p,'band1'),fs);
[filts(2).Ha, filts(2).Hb] = parpeak(feq(2),Q,blockpanelget(p,'band2'),fs);
[filts(3).Ha, filts(3).Hb] = parpeak(feq(3),Q,blockpanelget(p,'band3'),fs);
[filts(4).Ha, filts(4).Hb] = parpeak(feq(4),Q,blockpanelget(p,'band4'),fs);
[filts(5).Ha, filts(5).Hb] = parpeak(feq(5),Q,blockpanelget(p,'band5'),fs);
[filts(6).Ha, filts(6).Hb] = parhsf(feq(6),blockpanelget(p,'band6'),fs);

flag = 1;
%Loop until end of the stream (flag) and until panel is opened
while flag && p.flag
   
  % Obtain gains of the respective filters
  G = blockpanelget(p,'band1','band2','band3','band4','band5','band6');
  
  % Check if any of the user-defined gains is different from the actual ones
  % and do recomputation.
   for ii=1:numel(filts)
     if G(ii)~=filts(ii).G
        filts(ii).G = G(ii);
        if strcmpi('lsf',filts(ii).type)
           [filts(ii).Ha, filts(ii).Hb] = parlsf(feq(ii),filts(ii).G,fs);
        elseif strcmpi('hsf',filts(ii).type)
           [filts(ii).Ha, filts(ii).Hb] = parhsf(feq(ii),filts(ii).G,fs);
        elseif strcmpi('peak',filts(ii).type)
           [filts(ii).Ha, filts(ii).Hb] = parpeak(feq(ii),Q,filts(ii).G,fs);   
        else
           error('Uknown filter type.');
        end
     end
  end
       
  % Read block of length bufLen
  [f,flag] = blockread(bufLen);
 
  % Do the filtering. Output of one filter is passed to the input of the
  % following filter. Internal conditions are used and stored. 
  for ii=1:numel(filts)
    [f,filts(ii).Z] = filter(filts(ii).Ha,filts(ii).Hb,f,filts(ii).Z);
  end

  % Play the block
  blockplay(f);
end
blockdone(p);

function [Ha,Hb]=parlsf(fc,G,Fs)
% PARLSF Parametric Low-Shelwing filter
%   Input parameters:
%         fm    : Cut-off frequency
%         G     : Gain in dB
%         Fs    : Sampling frequency
%   Output parameters:
%         Ha    : Transfer function numerator coefficients.
%         Hb    : Transfer function denominator coefficients.
%
%  For details see Table 5.4 in the reference.
Ha = zeros(3,1);
Hb = zeros(3,1);
%b0
Hb(1) = 1;
Ha(1) = 1;
K = tan(pi*fc/Fs);
if G>0
   V0=10^(G/20);
   den = 1 + sqrt(2)*K + K*K;
   % a0
   Ha(1) = (1+sqrt(2*V0)*K+V0*K*K)/den;
   % a1
   Ha(2) = 2*(V0*K*K-1)/den;
   % a2
   Ha(3) = (1-sqrt(2*V0)*K+V0*K*K)/den;
   % b1
   Hb(2) = 2*(K*K-1)/den;
   % b2
   Hb(3) = (1-sqrt(2)*K+K*K)/den;
elseif G<0
   V0=10^(-G/20);
   den = 1 + sqrt(2*V0)*K + V0*K*K;
   % a0
   Ha(1) = (1+sqrt(2)*K+K*K)/den;
   % a1
   Ha(2) = 2*(K*K-1)/den;
   % a2
   Ha(3) = (1-sqrt(2)*K+K*K)/den;
   % b1
   Hb(2) = 2*(V0*K*K-1)/den;
   % b2
   Hb(3) = (1-sqrt(2*V0)*K+V0*K*K)/den;
end

function [Ha,Hb]=parpeak(fc,Q,G,Fs)
% PARLSF Parametric Peaking filter
%   Input parameters:
%         fm    : Cut-off frequency
%         Q     : Filter quality. Q=fc/B, where B is filter bandwidth.
%         G     : Gain in dB
%         Fs    : Sampling frequency
%   Output parameters:
%         Ha    : Transfer function numerator coefficients.
%         Hb    : Transfer function denominator coefficients.
%
%  For details see Table 5.3 in the reference.
Ha = zeros(3,1);
Hb = zeros(3,1);
%b0
Hb(1) = 1;
Ha(1) = 1;
K = tan(pi*fc/Fs);
if G>0
   V0=10^(G/20);
   den = 1 + K/Q + K*K;
   % a0
   Ha(1) = (1+V0*K/Q+K*K)/den;
   % a1
   Ha(2) = 2*(K*K-1)/den;
   % a2
   Ha(3) = (1-V0*K/Q+K*K)/den;
   % b1
   Hb(2) = 2*(K*K-1)/den;
   % b2
   Hb(3) = (1-K/Q+K*K)/den;
elseif G<0
   V0=10^(-G/20);
   den = 1 + V0*K/Q + K*K;
   % a0
   Ha(1) = (1+K/Q+K*K)/den;
   % a1
   Ha(2) = 2*(K*K-1)/den;
   % a2
   Ha(3) = (1-K/Q+K*K)/den;
   % b1
   Hb(2) = 2*(K*K-1)/den;
   % b2
   Hb(3) = (1-V0*K/Q+K*K)/den;
end

function [Ha,Hb]=parhsf(fm,G,Fs)
% PARLSF Parametric High-shelving filter
%   Input parameters:
%         fm    : Cut-off frequency
%         G     : Gain in dB
%         Fs    : Sampling frequency
%   Output parameters:
%         Ha    : Transfer function numerator coefficients.
%         Hb    : Transfer function denominator coefficients.
%
%  For details see Table 5.3 in the reference.
Ha = zeros(3,1);
Hb = zeros(3,1);
%b0
Hb(1) = 1;
Ha(1) = 1;
K = tan(pi*fm/Fs);
if G>0
   V0=10^(G/20);
   den = 1 + sqrt(2)*K + K*K;
   % a0
   Ha(1) = (V0+sqrt(2*V0)*K+K*K)/den;
   % a1
   Ha(2) = 2*(K*K-V0)/den;
   % a2
   Ha(3) = (V0-sqrt(2*V0)*K+K*K)/den;
   % b1
   Hb(2) = 2*(K*K-1)/den;
   % b2
   Hb(3) = (1-sqrt(2)*K+K*K)/den;
elseif G<0
   V0=10^(-G/20);
   den = V0 + sqrt(2*V0)*K + K*K;
   % a0
   Ha(1) = (1+sqrt(2)*K+K*K)/den;
   % a1
   Ha(2) = 2*(K*K-1)/den;
   % a2
   Ha(3) = (1-sqrt(2)*K+K*K)/den;
   % b1
   Hb(2) = 2*(K*K/V0-1)/den;
   % b2
   Hb(3) = (1-sqrt(2/V0)*K+K*K/V0)/den;
end





