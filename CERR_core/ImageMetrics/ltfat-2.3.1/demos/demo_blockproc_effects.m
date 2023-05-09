function demo_blockproc_effects(source,varargin) 
%-*- texinfo -*-
%@deftypefn {Function} demo_blockproc_effects
%@verbatim
%DEMO_BLOCKPROC_EFFECTS Various vocoder effects using DGT
%   Usage: demo_blockproc_effects('gspi.wav')
%
%   For additional help call DEMO_BLOCKPROC_EFFECTS without arguments.
%   This demo works correctly only with the sampling rate equal to 44100 Hz.
%
%   This script demonstrates several real-time vocoder effects. Namely:
%
%      1) Robotization effect: Achieved by doing DGT reconstruction using
%         absolute values of coefficients only.
%
%      2) Whisperization effect: Achieved by randomizing phase of DGT
%         coefficients.
%
%      3) Pitch shifting effect: Achieved by stretching/compressing
%         coefficients along frequency axis.
%
%      4) Audio morphing: Input is morphed with a background sound such
%         that the phase of DGT coefficients is substituted by phase
%         of DGT coefficients of the background signal. 
%         File beat.wav (at 44,1kHz) (any sound will do) is expected to 
%         be in the search path, oherwise the effect will be disabled.   
%
%   This demo was created for the Lange Nacht der Forschung 4.4.2014 event.
%   
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_blockproc_effects.html}
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

% AUTHORS: Zdenek Prusa, Nicki Holighaus

if demo_blockproc_header(mfilename,nargin)
   return;
end

fobj = blockfigure();

% Common block setup
bufLen = 1024;

% Morphing params
Fmorph = frametight(frame('dgtreal',{'hann',512},128,512,'timeinv'));
Fmorph = blockframeaccel(Fmorph, bufLen,'segola');

haveWav = 0;
try
   [ff, fsbeat] = wavload('beat.wav'); ff = ff(:,1);
   %ff = 0.8*resample(ff,4,1);
   ffblocks = reshape(postpad(ff,ceil(size(ff,1)/bufLen)*bufLen),bufLen,[]);
   cidx = 1;
   haveWav = 1;
catch
   warning('beat.wav not found. morphing effect is disabled.');
end

if haveWav && fsbeat~=44100
    error('%s: beat.wav must be sampled at 44.1 kHz.',upper(mfilename));
end

% Plain analysis params
Fana = frame('dgtreal',{'hann',882},300,3000);
Fana = blockframeaccel(Fana, bufLen,'segola');

% Robotization params
Mrob = 2^12;
Frob = frametight(frame('dgtreal',{'hann',Mrob},Mrob/8,Mrob,'timeinv'));
Frob = blockframeaccel(Frob, bufLen,'segola');

% Whisperization params
Mwhis = 512;
Fwhis = frametight(frame('dgtreal',{'hann',512},128,Mwhis));
Fwhis = blockframeaccel(Fwhis, bufLen,'segola');

% Pitch shift

% Window length in ms
M = 1024;
a = 512;
[F] = frametight(frame('dgtreal',{'hann',1024},a,M,'timeinv'));
Fa = blockframeaccel(F, bufLen,'segola');
Fs = Fa;

Mhalf = floor(M/2) + 1;
scale = (0:Mhalf-1)/Mhalf;
scale = scale(:);

shiftRange = 12;

scaleTable = round(scale*2.^(-(1:shiftRange)/12)*Mhalf)+1;
scaleTable2 = round(scale*2.^((1:shiftRange)/12)*Mhalf)+1;
scaleTable2(scaleTable2>Mhalf) = Mhalf;

phaseCorr = exp(abs(bsxfun(@minus,scaleTable,(1:size(scaleTable,1))'))./M*2*pi*1i*a);
phaseCorr2 = exp(abs(bsxfun(@minus,scaleTable2,(1:size(scaleTable2,1))'))./M*2*pi*1i*a);
fola = [];
phasecorrVect = ones(Mhalf,1,'single');

if haveWav
% Basic Control pannel (Java object)
parg = {
        {'GdB','Gain',-20,20,0,21},...
        {'Eff','Effect',0,4,0,5},...
        {'Shi','Shift',-shiftRange,shiftRange,0,2*shiftRange+1}
       };
else
parg = {
        {'GdB','Gain',-20,20,0,21},...
        {'Eff','Effect',0,3,0,4},...
        {'Shi','Shift',-shiftRange,shiftRange,0,2*shiftRange+1}
       };
end

p = blockpanel(parg);

% Setup blocktream
try
   fs=block(source,varargin{:},'loadind',p,'L',bufLen);
catch
    % Close the windows if initialization fails
    blockdone(p,fobj);
    err = lasterror;
    error(err.message);
end

if fs~=44100
    error('%s: This demo only works with fs=44100 Hz.',upper(mfilename));
end

p.setVisibleParam('Shi',0);


oldEffect = 0;
flag = 1;
ffola = [];
%Loop until end of the stream (flag) and until panel is opened
while flag && p.flag
   gain = blockpanelget(p,'GdB');
   gain = 10.^(gain/20);
   effect = blockpanelget(p,'Eff');
   shift = fix(blockpanelget(p,'Shi'));
   
   effectChanged = 0;
   if oldEffect ~= effect
       effectChanged = 1;
   end
   oldEffect = effect;
       
   

   % Read block of data
   [f,flag] = blockread();

   % Apply gain
   f=f*gain;
   if effect ==0
       % Just plot spectrogram
       if effectChanged
          % Flush overlaps used in blockana and blocksyn
          p.setVisibleParam('Shi',0);
          % Now we can merrily continue
       end
       % Obtain DGT coefficients
       c = blockana(Fana, f);
       blockplot(fobj,Fana,c(:,1));
       
       fhat = f;
   elseif effect == 1
   % Robotization
   if effectChanged
       % Flush overlaps used in blockana and blocksyn
       p.setVisibleParam('Shi',0);
       % Now we can merrily continue
   end
   
   % Obtain DGT coefficients
   c = blockana(Frob, f);
   
   % Do the actual coefficient shift
   cc = Frob.coef2native(c,size(c));
   
   if(strcmpi(source,'playrec'))
      % Hum removal (aka low-pass filter)
      cc(1:2,:,:) = 0;
   end
   
   c = Frob.native2coef(cc);
   
   c = abs(c);
   
   % Plot the transposed coefficients
   blockplot(fobj,Frob,c(:,1));
   
   % Reconstruct from the modified coefficients
   fhat = blocksyn(Frob, c, size(f,1));
   
   elseif effect == 2
       % Whisperization
   if effectChanged
       p.setVisibleParam('Shi',0);
       % Now we can merrily continue
   end

    c = blockana(Fwhis, f);
   
    % Do the actual coefficient shift
    cc = Fwhis.coef2native(c,size(c));
   
    if(strcmpi(source,'playrec'))
      % Hum removal (aka low-pass filter)
      cc(1:2,:,:) = 0;
    end
   
    c = Fwhis.native2coef(cc);
   
    c = abs(c).*exp(i*2*pi*randn(size(c)));
  
   
    % Plot the transposed coefficients
    blockplot(fobj,Fwhis,c(:,1));
   
    % Reconstruct from the modified coefficients
    fhat = blocksyn(Fwhis, c, size(f,1));
   elseif effect == 3
   if effectChanged
       p.setVisibleParam('Shi',1);
       % Now we can merrily continue
   end
       

          % Obtain DGT coefficients
   c = blockana(Fa, f);
   
   % Do the actual coefficient shift
   cc = Fa.coef2native(c,size(c));

       cTmp = zeros(size(cc),class(c));
    if shift<0
       slices = size(cc,2);
       for s = 1:slices
          phasecorrVect = phasecorrVect.*phaseCorr(:,-shift);
          cTmp(scaleTable(:,-shift),s,:) =... 
          bsxfun(@times,cc(1:numel(scaleTable(:,-shift)),s,:),phasecorrVect);
       end
    elseif shift>0
       slices = size(cc,2);
       for s = 1:slices
          phasecorrVect = phasecorrVect.*phaseCorr2(:,shift);
          cTmp(scaleTable2(:,shift),s,:) =... 
          bsxfun(@times,cc(1:numel(scaleTable2(:,shift)),s,:),phasecorrVect);
       end
       %cc = [zeros(shift,size(cc,2),size(cc,3))];
    else
        cTmp = cc;
    end
   
   c = Fa.native2coef(cTmp);
 
   
   % Reconstruct from the modified coefficients
   fhat = blocksyn(Fs, c, size(f,1));
   
   [c2,fola] = blockana(Fa,fhat,fola);
   
   % Plot the transposed coefficients
   blockplot(fobj,Fa,c2(:,1));
   
   elseif effect == 4
      if effectChanged
       % Flush overlaps used in blockana and blocksyn
       p.setVisibleParam('Shi',0);
       % Now we can merrily continue
     end
       % Audio morphing effect
       
       
       [cff,ffola] = blockana(Fmorph, ffblocks(:,cidx), ffola);
       cidx = mod(cidx,size(ffblocks,2)) + 1;
       % Obtain DGT coefficients
       c = blockana(Fmorph, f);
       
       c = bsxfun(@times,abs(c),exp(1i*(angle(cff) )));

   
        % Plot the transposed coefficients
        blockplot(fobj,Fmorph,c(:,1));
   
        % Reconstruct from the modified coefficients
        fhat = blocksyn(Fmorph, c, size(f,1)); 
   
   end

   % Enqueue to be played
   blockplay(fhat);
   blockwrite(fhat);
end
% Clear and close all
blockdone(p,fobj);

