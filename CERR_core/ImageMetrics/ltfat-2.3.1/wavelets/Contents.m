% LTFAT - Wavelets
%
%   Zdenek Prusa, 2013 - 2018.
%
%   If you use the wavelets module for a scientific work, please cite:
%
%   Z. Průša, P. L. Soendergaard, and P. Rajmic. “Discrete Wavelet Transforms in the Large
%   Time-Frequency Analysis Toolbox for MATLAB/GNU Octave.” ACM Trans. Math. Softw. 42, 4,
%   Article 32, 2016. DOI: 10.1145/2839298
%   
%   Basic analysis/synthesis
%      FWT               - Fast Wavelet Transform 
%      IFWT              - Inverse Fast Wavelet Transform
%      FWT2              - 2D Fast Wavelet Transform 
%      IFWT2             - 2D Inverse Fast Wavelet Transform
%      UFWT              - Undecimated Fast Wavelet Transform
%      IUFWT             - Inverse Undecimated Fast Wavelet Transform 
%      FWTLENGTH         - Length of Wavelet system to expand a signal
%      FWTCLENGTH        - Lengths of the wavelet coefficient subbands
%
%   Advanced analysis/synthesis
%      WFBT              - Transform using general Wavelet Filter Bank Tree 
%      IWFBT             - Inverse transform using general Wavelet Filter Bank Tree
%      UWFBT             - Undecimated transform using general Wavelet Filter Bank Tree 
%      IUWFBT            - Inverse Undecimated transform using general Wavelet Filter Bank Tree
%      WPFBT             - Wavelet Packet Transform using general Wavelet Filter Bank Tree 
%      IWPFBT            - Inverse Wavelet Packet Transform using general Wavelet Filter Bank Tree
%      UWPFBT            - Undecimated Wavelet Packet Transform using general Wavelet Filter Bank Tree 
%      IUWPFBT           - Inverse Undecimated Wavelet Packet Transform using general Wavelet Filter Bank Tree
%      WPBEST            - Best Tree selection
%      WFBTLENGTH        - Length of Wavelet filter bank system to expand a signal
%      WFBTCLENGTH       - Lengths of Wavelet filter bank coefficient subbands
%      WPFBTCLENGTH      - Lengths of Wavelet Packet transform coefficient subbands
%
%   Dual-tree complex wavelet transform
%      DTWFB             - Dual-Tree Wavelet Filter Bank
%      IDTWFB            - Inverse Dual-Tree Wavelet Filter Bank
%      DTWFBREAL         - Dual-Tree Wavelet Filter Bank for real-valued signals
%      IDTWFBREAL        - Inverse Dual-Tree Wavelet Filter Bank for real-valued signals
%
%   Wavelet Filterbank trees manipulation
%      WFBTINIT          - Wavelet Filter Bank tree structure initialization
%      DTWFBINIT         - Dual-Tree wavelet filter bank structure initialization
%      WFBTPUT           - Puts node (basic filter bank) to the specific  tree coordinates
%      WFBTREMOVE        - Removes node (basic filter bank) from the specific tree coordinates
%      WFBT2FILTERBANK   - WFBT or FWT non-iterated filter bank using the multi-rate identity
%      WPFBT2FILTERBANK  - WPFBT non-iterated filter bank using the multi-rate identity
%      DTWFB2FILTERBANK  - DTWFB or DTWFBREAL non-iterated filter bank
%      FWTINIT           - Basic Wavelet Filters structure initialization
%
%   Frame properties of wavelet filter banks:
%      WFBTBOUNDS        - Frame bounds of WFBT and FWT (or UWFBT and UFWT)
%      WPFBTBOUNDS       - Frame bounds of WPFBT or UWPFBT
%      DTWFBBOUNDS       - Frame bounds of DTWFB
%  
%   Plots
%      PLOTWAVELETS      - Plot wavelet coefficients
%      WFILTINFO         - Plot wavelet filters impulse and frequency responses and approximation of scaling and wavelet functions
%      WFILTDTINFO       - Plot the same as WFILTINFO but for dual-tree wavelet transform
%
%   Auxilary
%      WAVFUN            - Approximate of the continuous scaling and wavelet functions
%      WAVCELL2PACK      - Changes wavelet coefficient storing format
%      WAVPACK2CELL      - Changes wavelet coefficient storing format back
%
%   Wavelet Filters defined in the time-domain
%      WFILT_ALGMBAND    - An ALGebraic construction of orthonormal M-BAND wavelets with perfect reconstruction
%      WFILT_CMBAND      - M-Band cosine modulated wavelet filters
%      WFILT_COIF        - Coiflets
%      WFILT_DB          - DauBechies orthogonal filters (ortonormal base)
%      WFILT_DDEN        - Double-DENsity dwt filters (tight frame)
%      WFILT_DGRID       - Dense GRID framelets (tight frame, symmetric)
%      WFILT_HDEN        - Higher DENsity dwt filters (tight frame, frame)  
%      WFILT_LEMARIE       - Battle and Lemarie quadrature filters
%      WFILT_MATLABWRAPPER - Wrapper of the wfilters function from the Matlab Wavelet Toolbox 
%      WFILT_MBAND           - M-band filters
%      WFILT_REMEZ           - Wavelet orthonogal filters based on the Remez Exchange algorithm
%      WFILT_SYMDS           - SYMmetric wavelet Dyadic Siblings (frames)
%      WFILT_SPLINE          - Biorthogonal spline wavelet filters
%      WFILT_SYM             - Least asymmetric Daubechies wavelet filters
%      WFILT_SYMDDEN         - Symmetric Double-DENsity dwt filters (tight frame)
%      WFILT_SYMORTH         - Symmetric nearly-orthogonal and orthogonal nearly-symmetric wav. filters
%      WFILT_SYMTIGHT        - Symmetric nearly shift-invariant tight frame wavelets
%      WFILT_QSHIFTA         - First tree filters from WFILTDT_QSHIFT 
%      WFILT_QSHIFTB         - Second tree filters from WFILTDT_QSHIFT 
%      WFILT_ODDEVENA        - First tree filters from WFILTDT_ODDEVEN 
%      WFILT_ODDEVENB        - Second tree filters from WFILTDT_ODDEVEN 
%      WFILT_OPTSYMA         - First tree filters from WFILTDT_OPTSYM 
%      WFILT_OPTSYMB         - Second tree filters from WFILTDT_OPTSYM 
%      WFILT_DDENA           - First tree filters from WFILTDT_DDEN 
%      WFILT_DDENB           - Second tree filters from WFILTDT_DDEN 
%
%   Dual-Tree Filters
%      WFILTDT_QSHIFT        - Kingsbury's quarter-shift filters
%      WFILTDT_OPTSYM        - Optimizatized Symmetric Self-Hilbertian Filters
%      WFILTDT_ODDEVEN       - Kingsbury's symmetric odd and even biorthogonal filters
%      WFILTDT_DDEN          - Double-density dual-tree filters
%
%  For help, bug reports, suggestions etc. please visit 
%  http://github.com/ltfat/ltfat/issues
%
%   Url: http://ltfat.github.io/doc/wavelets/Contents.html

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


