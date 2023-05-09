function [c,info] = ufwt(f,w,J,varargin)
%-*- texinfo -*-
%@deftypefn {Function} ufwt
%@verbatim
%UFWT  Undecimated Fast Wavelet Transform
%   Usage:  c = ufwt(f,w,J);
%           [c,info] = ufwt(...);
%
%   Input parameters:
%         f     : Input data.
%         w     : Wavelet Filterbank.
%         J     : Number of filterbank iterations.
%
%   Output parameters:
%         c     : Coefficients stored in L x(J+1) matrix.
%         info  : Transform paramaters struct.
%
%   UFWT(f,w,J) computes redundant time (or shift) invariant
%   wavelet representation of the input signal f using wavelet filters
%   defined by w in the "a-trous"  algorithm. 
%
%   For all accepted formats of the parameter w see the FWTINIT function.
%
%   [c,info]=UFWT(f,w,J) additionally returns the info struct. 
%   containing the transform parameters. It can be conviniently used for 
%   the inverse transform IUFWT e.g. fhat = iUFWT(c,info). It is also 
%   required by the PLOTWAVELETS function.
%
%   The coefficents c are so called undecimated Discrete Wavelet transform
%   of the input signal f, if w defines two-channel wavelet filterbank.
%   Other names for this version of the wavelet transform are: the
%   time-invariant wavelet transform, the stationary wavelet transform,
%   maximal overlap discrete wavelet transform or even the "continuous"
%   wavelet transform (as the time step is one sample). However, the
%   function accepts any number filters (referred to as M) in the basic
%   wavelet filterbank and the number of columns of c is then J(M-1)+1.
%
%   For one-dimensional input f of length L, the coefficients c are
%   stored as columns of a matrix. The columns are ordered with inceasing
%   central frequency of the respective subbands.
%
%   If the input f is L xW matrix, the transform is applied
%   to each column and the outputs are stacked along third dimension in the
%   L xJ(M-1)+1 xW data cube.
%
%   Filter scaling
%   --------------
%
%   When compared to FWT, UFWT subbands are gradually more and more 
%   redundant with increasing level of the subband. If no scaling of the 
%   filters is introduced, the energy of subbands tends to grow with increasing
%   level.
%   There are 3 flags defining filter scaling:
%
%      'sqrt'
%               Each filter is scaled by 1/sqrt(a), where a is the hop
%               factor associated with it. If the original filterbank is
%               orthonormal, the overall undecimated transform is a tight
%               frame.
%               This is the default.
%
%      'noscale'
%               Uses filters without scaling.
%
%      'scale'
%               Each filter is scaled by 1/a.
%
%   If 'noscale' is used, 'scale' has to be used in IUFWT (and vice
%   versa) in order to obtain a perfect reconstruction.
%
%   Boundary handling:
%   ------------------
%
%   c=UFWT(f,w,J) uses periodic boundary extension. The extensions are
%   done internally at each level of the transform, rather than doing the
%   prior explicit padding.
%
%   Examples:
%   ---------
%
%   A simple example of calling the UFWT function:
%
%     [f,fs] = greasy;
%     J = 8;
%     [c,info] = ufwt(f,'db8',J);
%     plotwavelets(c,info,fs,'dynrange',90);
%
%
%   References:
%     M. Holschneider, R. Kronland-Martinet, J. Morlet, and P. Tchamitchian.
%     A real-time algorithm for signal analysis with the help of the wavelet
%     transform. In Wavelets. Time-Frequency Methods and Phase Space,
%     volume 1, page 286, 1989.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/ufwt.html}
%@seealso{iufwt, plotwavelets}
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

% AUTHOR: Zdenek Prusa

complainif_notenoughargs(nargin,3,'UFWT');
complainif_notposint(J,'J');

definput.import = {'uwfbtcommon'};
[flags]=ltfatarghelper({},definput,varargin);

% Initialize the wavelet filters structure
w = fwtinit(w);

%% ----- step 1 : Verify f and determine its length -------
% Change f to correct shape.
[f,Ls]=comp_sigreshape_pre(f,upper(mfilename),0);
if(Ls<2)
   error('%s: Input signal seems not to be a vector of length > 1.',upper(mfilename));
end

%% ----- step 2 : Run computation
c = comp_ufwt(f,w.h,w.a,J,flags.scaling);

%% ----- Optionally : Fill info struct ----
if nargout>1
   info.fname = 'ufwt';
   info.wt = w;
   info.J = J;
   info.scaling = flags.scaling;
end



