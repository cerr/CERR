% LTFAT - Gabor analysis
%
%  Peter L. Soendergaard, 2007 - 2018.
%
%  Basic Time/Frequency analysis
%    TCONV          -  Twisted convolution
%    DSFT           -  Discrete Symplectic Fourier Transform
%    ZAK            -  Zak transform
%    IZAK           -  Inverse Zak transform
%    COL2DIAG       -  Move columns of a matrix to diagonals
%    S0NORM         -  S0-norm
%
%  Gabor systems
%    DGT            -  Discrete Gabor transform
%    IDGT           -  Inverse discrete Gabor transform
%    ISGRAM         -  Iterative reconstruction from spectrogram
%    ISGRAMREAL     -  Iterative reconstruction from spectrogram for real-valued signals
%    DGT2           -  2D Discrete Gabor transform
%    IDGT2          -  2D Inverse discrete Gabor transform
%    DGTREAL        -  DGT for real-valued signals
%    IDGTREAL       -  IDGT for real-valued signals
%    GABWIN         -  Evaluate Gabor window
%    PROJKERN	    -  Projection of Gabor coefficients onto kernel space
%    DGTLENGTH      -  Length of Gabor system to expand a signal
%
%  Multi-Gabor systems
%    MULTIDGTREALMP -  Matching pursuit decomposition in Multi-Gabor system 
%
%  Wilson bases and WMDCT
%    DWILT          -  Discrete Wilson transform
%    IDWILT         -  Inverse discrete Wilson transform
%    DWILT2         -  2-D Discrete Wilson transform
%    IDWILT2        -  2-D inverse discrete Wilson transform
%    WMDCT          -  Modified Discrete Cosine transform
%    IWMDCT         -  Inverse WMDCT
%    WMDCT2         -  2-D WMDCT
%    IWMDCT2        -  2-D inverse WMDCT
%    WIL2RECT       -  Rectangular layout of Wilson coefficients
%    RECT2WIL       -  Inverse of WIL2RECT
%    WILWIN         -  Evaluate Wilson window
%    DWILTLENGTH    -  Length of Wilson/WMDCT system to expand a signal
%
%  Reconstructing windows
%    GABDUAL        -  Canonical dual window
%    GABTIGHT       -  Canonical tight window
%    GABFIRDUAL     -  FIR optimized dual window 
%    GABOPTDUAL     -  Optimized dual window
%    GABFIRTIGHT    -  FIR optimized tight window
%    GABOPTTIGHT    -  Optimized tight window
%    GABCONVEXOPT   -  Optimized window
%    GABPROJDUAL    -  Dual window by projection
%    GABMIXDUAL     -  Dual window by mixing windows
%    WILORTH        -  Window of Wilson/WMDCT orthonormal basis
%    WILDUAL        -  Riesz dual window of Wilson/WMDCT basis 
%
%  Conditions numbers
%    GABFRAMEBOUNDS -  Frame bounds of Gabor system
%    GABRIESZBOUNDS -  Riesz sequence/basis bounds of Gabor system
%    WILBOUNDS      -  Frame bounds of Wilson basis
%    GABDUALNORM    -  Test if two windows are dual
%    GABFRAMEDIAG   -  Diagonal of Gabor frame operator
%    WILFRAMEDIAG   -  Diagonal of Wilson/WMDCT frame operator
%
%  Phase gradient methods and reassignment
%    GABPHASEGRAD   -  Instantaneous time/frequency from signal
%    GABPHASEDERIV  -  Phase derivatives
%    GABREASSIGN    -  Reassign positive distribution
%    GABREASSIGNADJUST - Adjustable t-f reassignment
%
%  Phase reconstruction
%    CONSTRUCTPHASE     - Phase construction from abs. values of DGT
%    CONSTRUCTPHASEREAL - CONSTRUCTPHASE for DGTREAL
%
%  Phase conversions
%    PHASELOCK       -  Phase Lock Gabor coefficients to time. inv.
%    PHASEUNLOCK     -  Undo phase locking
%    PHASELOCKREAL   -  Same as PHASELOCK for DGTREAL
%    PHASEUNLOCKREAL -  Same as PHASEUNLOCK for IDGTREAL
%    SYMPHASE        -  Convert to symmetric phase
%
%  Support for non-separable lattices
%    MATRIX2LATTICETYPE - Matrix form to standard lattice description
%    LATTICETYPE2MATRIX - Standard lattice description to matrix form
%    SHEARFIND      -  Shears to transform a general lattice to a separable
%    NOSHEARLENGTH  -  Next transform side not requiring a frequency side shear
%
%  Plots
%    TFPLOT         -  Plot coefficients on the time-frequency plane
%    PLOTDGT        -  Plot DGT coefficients
%    PLOTDGTREAL    -  Plot DGTREAL coefficients
%    PLOTDWILT      -  Plot DWILT coefficients
%    PLOTWMDCT      -  Plot WMDCT coefficients
%    SGRAM          -  Spectrogram based on DGT
%    GABIMAGEPARS   -  Choose parameters for nice Gabor image
%    RESGRAM        -  Reassigned spectrogram
%    INSTFREQPLOT   -  Plot of the instantaneous frequency
%    PHASEPLOT      -  Plot of STFT phase
%
%  For help, bug reports, suggestions etc. please visit 
%  http://github.com/ltfat/ltfat/issues
%
%   Url: http://ltfat.github.io/doc/gabor/Contents.html

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

