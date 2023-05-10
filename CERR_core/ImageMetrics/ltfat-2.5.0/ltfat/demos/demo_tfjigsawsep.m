function demo_tfjigsawsep(demo) 
%DEMO_TFJIGSAWSEP - Decomposition of an audio signal into tonal, transient and residual layers
%
%   This demo shows how to use tfjigsawsep, where a signal is decomposed
%   into its tonal, transient and noisy residual layers. 
%   
%   The algorithm is based on [1]. It transforms a signal into a two-windowed
%   Gabor expansion such that one wide window shall lead to a high frequency
%   resolution (tonal layer is represented well) and a narrow one to a high
%   time resolution (transient layer is repr. well). The resulting Gabor
%   coefficients in the time-frequency plane are grided adaptively into rectangular
%   'supertiles', whithin one by one an entropy criterion decides, which
%   layer of the signal (tonal, transient) is represented better. This tile
%   will be kept if it is below a certain threshold, the other one is thrown
%   away. After running through the whole tf-plane, the respectively
%   leftover Gabor coefficients are transformed back and substracted 
%   from the original signal. By applying this procedure iteratively,
%   tonal and transient layers emerge.
%   A second version of the algorithm is available. Here the entropy
%   criterion chooses those tiles, where the tonal part of the signal is
%   represented better and is below a given threshold. The rest is set to
%   zero. The leftover Gabor coefficients are transformed back and
%   substracted from the original signal. Then the same is applied again to
%   choose those tiles, where the transient part is represented better.
%   After that, one gets the first approximation of the two layers. By
%   applying this procedure iteratively on the residual, tonal and
%   transient layers emerge.
%   
%   Figure 1: Separated layers
%      
%   See also: tfjigsawsep, plottfjigsawsep, dgtreal
%
%   References:
%     F. Jaillet and B. Torrésani. Time-frequency jigsaw puzzle: Adaptive
%     multiwindow and multilayered gabor expansions. IJWMIP, 5(2):293--315,
%     2007.
%     
%
%
%   Url: http://ltfat.github.io/doc/demos/demo_tfjigsawsep.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

% 
%   tfjigsawsep takes three very crucial parameters, t1,t2 and p. One has to
%   tweak and play with them to obtain good results:
%
%   t1 and t2 determine 'how likely' a part of the signal has been produced
%   by white noise. Good values are within (0.85,0.98), usually t2 > t1 works
%   well.
%
%   For speech signals lower values for t1 care for better noiseextraction
%   for musical signals, sometimes even t2 > 1 is necessary to extract all
%   the percussion elements
%
%   p determines the size of the supertiles and can be chosen within
%   (0,min(L/a1,M2/2)]. Values below 10 work best (tendencies):
%   higher for speech signals,lower for musical signals
%
%   Version 1 works particularly well for speech signals and detecting
%   percussive elements in musical signals, version 2 depicts the tonal layer
%   very nice, but is slower.
%
%   The default parameters are r1=r2=0.95, p=4 and the default settings for
%   the 3 Gabor systems are:
%   
%       "Tonal" system:     g1 = {'hann',4096}; a1 = 512; M1 = 4096;
%   
%       "Transient" system: g2 = {'hann',256};  a2 = 32;  M2 = 256;
%
%       "Residual" system:  g3 = {'hann',2048}; a3 = 512; M3 = 2048;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Several scenarios are provided to give a demonstration, what effects the
% choice of the parameters have. Declare the corresp. string below.
%
% glockenspiel signal with added noise - version 2 of the algorithm:
%    'glo1': suitable parameters
%    'glo2': supertile size too large, tonal parts are in the transient layer
%    'glo3': t1 too large, t2 too small - transient parts are in the tonal
%            layer
%
% speech signal with added noise, a person says 'the cocktailpartyeffect' -
% version 1:
%    'spe1': suitable parameters
%    'spe2': supertile size too small, the algorithm cannot detect the
%            transients that are essential for speech signals properly
%    'spe3': t2 too large, tonal parts are in the transient layer
%
% synthetic test signal with dirac-like impulses and added noise -
% version 2:
%    'syn': the algorithm struggles with seperating high frequency impulses
%           and noise
%

%AUTHOR: Daniel Haider, 2017 

if nargin < 1, demo = 'syn'; end

switch demo
    case 'glo1'
        [f,fs] = gspi;
        f = f(1:2^16);
        f = f + 0.0001*randn(size(f));
        p = 2;
        r1 = 0.88;
        r2 = 0.87;
        tfjigsawsep(f,r1,r2,p,'plot','ver2','fs',fs);
    case 'glo2'
        [f,fs] = gspi;
        f = f(1:2^16);
        f = f + 0.001*randn(size(f));
        p = 10;
        r1 = 0.92;
        r2 = 0.93;        
        tfjigsawsep(f,r1,r2,p,'plot','ver2','fs',fs);
    case 'glo3'
        [f,fs] = gspi;
        f = f(1:2^16);
        f = f + 0.001*randn(size(f));
        p = 10;
        r1 = 0.98;
        r2 = 0.8;
        tfjigsawsep(f,r1,r2,p,'plot','ver2','fs',fs);
    case 'spe1'
        [f,fs] = cocktailparty;
        f = f(1:10^5);
        f = f + 0.001*rand(size(f));
        p = 10;
        r1 = 0.94;
        r2 = 0.87;
        tfjigsawsep(f,r1,r2,p,'plot','fs',fs);  
    case 'spe2'
        [f,fs] = cocktailparty;
        f = f(1:10^5);
        f = f + 0.001*rand(size(f));
        p = 2;
        r1 = 0.94;
        r2 = 0.87;
        tfjigsawsep(f,r1,r2,p,'plot','fs',fs);
    case 'spe3'
        [f,fs] = cocktailparty;
        f = f(1:10^5);
        f = f + 0.001*rand(size(f));
        p = 10;
        r1 = 0.94;
        r2 = 0.98;
        tfjigsawsep(f,r1,r2,p,'plot','fs',fs);
    case 'syn'
        [f,fs] = synthtest;
        f = f + 0.001*randn(size(f));
        p = 2;
        r1 = 0.85;
        r2 = 0.82;
        tfjigsawsep(f,r1,r2,p,'plot','ver2','fs',fs);   
    otherwise
        error('Please check the spelling of the string!')
end

function [s,fs] = synthtest()
amp=0.6; 
fs=44100;
dur1=1;
dur2=1.5;
freq1=440;
freq2=415.30;
freq3=392;
freq4=369.99;
val1=0:1/fs:dur1;
val2=0:1/fs:dur2;
a1 = amp*sin(2*pi* freq1*val1);
a2 = amp*sin(2*pi* freq2*val1);
a3 = amp*sin(2*pi* freq3*val1);
a4 = amp*sin(2*pi* freq4*val2);
b = zeros(1,length(a1)+length(a2)+length(a3)+length(a4));
b(1,1:1378:44096)=1;
b(1,44100:2756:88196)=1;
b(1,88200:5512:132296)=1;
b(1,132300:16538:198452)=1;
a = [a1,a2,a3,a4];
s = a+b;
s = setnorm(s,'wav');



