% LTFAT - Frames
%
%  Peter L. Soendergaard, 2012 - 2018.
%
%  Creation of a frame object
%    FRAME             - Construct a new frame
%    FRAMEPAIR         - Construct a pair of frames
%    FRAMEDUAL         - The canonical dual frame
%    FRAMETIGHT        - The canonical tight frame
%    FRAMEACCEL        - Precompute arrays for faster application
%
%  Linear operators
%    FRANA             - Frame analysis
%    FRSYN             - Frame synthesis
%    FRSYNMATRIX       - Frame synthesis operator matrix
%    FRGRAMIAN	       - Frame Gramian operator
%    FRAMEOPERATOR     - Frame operator
%    FRAMEDIAG         - Diagonal of frame operator
%    FRANAITER         - Iterative perfect reconstruction analysis
%    FRSYNITER         - Iterative perfect reconstruction synthesis
%
%  Visualization
%    PLOTFRAME         - Plot frame coefficients
%    FRAMEGRAM         - Plot energy of signal in frame space
%
%  Information about a frame
%    FRAMEBOUNDS       - Frame bounds
%    FRAMERED          - Redundancy of frame
%    FRAMELENGTH       - Length of frame to expand signal
%    FRAMELENGTHCOEF   - Length of frame given a set of coefficients
%    FRAMECLENGTH      - Number of coefficients given input signal length
%    FRAMEVECTORNORMS  - Norms of the frame vectors
%
%  Coefficients conversions
%    FRAMECOEF2NATIVE  - Convert to native transform format
%    FRAMENATIVE2COEF  - Convert native to column format
%    FRAMECOEF2TF      - Convert to time-frequency plane layout
%    FRAMETF2COEF      - Convert TF-plane layout to native
%    FRAMECOEF2TFPLOT  - Convert to time-frequency plane layout for plotting
%
%  Non-linear analysis and synthesis
%    FRANABP           - Basis pursuit using the SALSA algorithm.
%    FRANAMP           - Orthogonal matching pursuit
%    FRANALASSO        - LASSO thresholding using Landweber iterations.
%    FRANAGROUPLASSO   - Group LASSO thresholding.
%    FRSYNABS          - Frame synthesis from magnitude of coefficients
%
%  For help, bug reports, suggestions etc. please visit 
%  http://github.com/ltfat/ltfat/issues
%
%   Url: http://ltfat.github.io/doc/frames/Contents.html

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

