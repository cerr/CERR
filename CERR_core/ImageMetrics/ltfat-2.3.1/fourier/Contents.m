% LTFAT - Basic Fourier and DCT analysis.
%
%  Peter L. Soendergaard, 2008 - 2018.
%
%  Support routines
%    FFTINDEX       -  Index of positive and negative frequencies.
%    MODCENT        -  Centered modulo operation.
%    FLOOR23        -  Previous number with only 2,3 factors
%    FLOOR235       -  Previous number with only 2,3,5 factors
%    CEIL23         -  Next number with only 2,3 factors
%    CEIL235        -  Next number with only 2,3,5 factors
%    NEXTFASTFFT    -  Next efficient FFT size (2,3,5,7).
%  
%  Basic Fourier analysis
%    DFT            -  Unitary discrete Fourier transform.
%    IDFT           -  Inverse of DFT.
%    FFTREAL        -  FFT for real valued signals.
%    IFFTREAL       -  Inverse of FFTREAL.
%    GGA            -  Generalized Goertzel Algorithm.
%    CHIRPZT        -  Chirped Z-transform.
%    FFTGRAM	    -  Plot energy of FFT.
%    PLOTFFT        -  Plot FFT coefficients.
%    PLOTFFTREAL    -  Plot FFTREAL coefficients.
%
%  Simple operations on periodic functions
%    INVOLUTE       -  Involution.
%    PEVEN          -  Even part of periodic function.
%    PODD           -  Odd part of periodic function.
%    PCONV          -  Periodic convolution.
%    PXCORR         -  Periodic crosscorrelation.
%    LCONV          -  Linear convolution.
%    LXCORR	    -  Linear crosscorrelation. 
%    ISEVENFUNCTION -  Test if function is even.
%    MIDDLEPAD      -  Cut or extend even function.
%
%  Periodic functions
%    EXPWAVE        -  Complex exponential wave.
%    PCHIRP         -  Periodic chirp.
%    PGAUSS         -  Periodic Gaussian.
%    PSECH          -  Periodic SECH.
%    PBSPLINE       -  Periodic B-splines.
%    SHAH           -  Shah distribution.
%    PHEAVISIDE     -  Periodic Heaviside function.
%    PRECT          -  Periodic rectangle function.
%    PSINC          -  Periodic sinc function.
%    PTPFUN         -  Periodic totally positive function of finite type.
%    PEBFUN         -  Periodic EB spline. 
%
%  Specialized dual windows
%    PTPFUNDUAL     -  Dual window for PTPFUN
%    PEBFUNDUAL     -  Dual window for PEBFUN
%
%  Hermite functions and fractional Fourier transforms
%    PHERM          -  Periodic Hermite functions.
%    HERMBASIS      -  Orthonormal basis of Hermite functions.    
%    DFRACFT        -  Discrete Fractional Fourier transform
%    FFRACFT        -  Fast Fractional Fourier transform
%
%  Approximation of continuous functions
%    FFTRESAMPLE    -  Fourier interpolation.
%    DCTRESAMPLE    -  Cosine interpolation.
%    PDERIV         -  Derivative of periodic function.
%    FFTANALYTIC    -  Analytic representation of a function.
%
%  Cosine and Sine transforms.
%    DCTI           -  Discrete cosine transform type I
%    DCTII          -  Discrete cosine transform type II
%    DCTIII         -  Discrete cosine transform type III
%    DCTIV          -  Discrete cosine transform type IV
%    DSTI           -  Discrete sine transform type I
%    DSTII          -  Discrete sine transform type II
%    DSTIII         -  Discrete sine transform type III
%    DSTIV          -  Discrete sine transform type IV
%
%  For help, bug reports, suggestions etc. please visit 
%  http://github.com/ltfat/ltfat/issues
%
%   Url: http://ltfat.github.io/doc/fourier/Contents.html

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


