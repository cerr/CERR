%-*- texinfo -*-
%@deftypefn {Function} demo_wavelets
%@verbatim
%DEMO_WAVELETS  Wavelet filter banks
%
%   This demo exemplifies the use of the wavelet filter bank trees. All 
%   representations use "least asymmetric" Daubechies wavelet orthonormal
%   filters 'sym8' (8-regular, length 16).
%
%   Figure 1: DWT representation
%
%      The filter bank tree consists of 11 levels of iterated 2-band basic
%      wavelet filter bank, where only the low-pass output is further 
%      decomposed. This results in 12 bands with octave resolution. 
%
%   Figure 2: 8-band DWT representation
%
%      The filter bank tree (effectively) consists of 3 levels of iterated
%      8-band basic wavelet filter bank resulting in 22 bands. Only the
%      low-pass output is decomposed at each level.
%
%   Figure 3: Full Wavelet filter bank tree representation
%
%      The filter bank tree depth is 8 and it is fully decomposed meaning
%      both outputs (low-pass and high-pass) of the basic filter bank is
%      plot further. This results in 256 bands linearly covering the 
%      frequency axis.
%
%   Figure 4: Full Wavelet filter bank tree representation
%
%      The same case as before, but symmetric nearly orthogonal basic
%      filter bank is used.
%
%   Figure 5: Full Dual-tree Wavelet filter bank representation
%
%      This is a 2 times redundant representation using Q-shift dual-tree
%      wavelet filters.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_wavelets.html}
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


% Read the test signal and crop it to the range of interest
[f,fs]=gspi;
f=f(10001:100000);
dr=50;
   
    
figure(1);
[c1,info]=fwt(f,'sym8',11);
plotwavelets(c1,info,fs,'dynrange',dr);



figure(2);
[c2,info]=wfbt(f,{'sym8',3,'quadband'});
plotwavelets(c2,info,fs,'dynrange',dr);


figure(3);
[c3,info]=wfbt(f,{'sym8',8,'full'});
plotwavelets(c3,info,fs,'dynrange',dr);


figure(4);
[c4,info]=wfbt(f,{'symorth3',8,'full'});
plotwavelets(c4,info,fs,'dynrange',dr);

figure(5);
[c5,info]=dtwfbreal(f,{'qshift5',8,'full','first','symorth3'});
plotwavelets(c5,info,fs,'dynrange',dr);





