function [c,info] = fwt(f,w,J,varargin)
%-*- texinfo -*-
%@deftypefn {Function} fwt
%@verbatim
%FWT   Fast Wavelet Transform
%   Usage:  c = fwt(f,w,J);
%           c = fwt(f,w,J,dim);
%           [c,info] = fwt(...);
%
%   Input parameters:
%         f     : Input data.
%         w     : Wavelet definition.
%         J     : Number of filterbank iterations.
%         dim   : Dimension to along which to apply the transform.
%
%   Output parameters:
%         c      : Coefficient vector.
%         info   : Transform parameters struct.
%
%   FWT(f,w,J) returns discrete wavelet coefficients of the input signal 
%   f using J iterations of the basic wavelet filterbank defined by
%   w using the fast wavelet transform algorithm (Mallat's algorithm).
%   The coefficients are the Discrete Wavelet transform (DWT) of the input 
%   signal f, if w defines two-channel wavelet filterbank. The following
%   figure shows DWT with J=3.
%
%   The function can apply the Mallat's algorithm using basic filterbanks
%   with any number of the channels. In such case, the transform have a
%   different name.
%
%   Several formats of the basic filterbank definition w are recognized.
%   One of them is a text string formed by a concatenation of a function 
%   name with the wfilt_ prefix followed by a list of numerical arguments
%   delimited by :. For example 'db10' will result in a call to 
%   wfilt_db(10) or 'spline4:4' in call to wfilt_spline(4,4) etc.
%   All filter defining functions can be listed by running
%   dir([ltfatbasepath,filesep,'wavelets',filesep,'wfilt_*']);
%   Please see help of the respective functions and follow references
%   therein.
%
%   For other recognized formats of w please see FWTINIT.
%
%   [c,info]=FWT(f,w,J) additionally returns struct. info containing 
%   transform parameters. It can be conviniently used for the inverse 
%   transform IFWT e.g. as fhat = iFWT(c,info). It is also required 
%   by the PLOTWAVELETS function.
%
%   If f is row/column vector, the subbands c are stored
%   in a single row/column in a consecutive order with respect to the
%   inceasing central frequency. The lengths of subbands are stored in 
%   info.Lc so the subbands can be easily extracted using WAVPACK2CELL.
%   Moreover, one can pass an additional flag 'cell' to obtain the 
%   coefficient directly in a cell array. The cell array can be again 
%   converted to a packed format using WAVCELL2PACK.
%
%   If the input f is a matrix, the transform is applied to each column
%   if dim==1 (default) and [Ls, W]=size(f). If dim==2
%   the transform is applied to each row [W, Ls]=size(f).
%   The output is then a matrix and the input orientation is preserved in
%   the orientation of the output coefficients. The dim paramerer has to
%   be passed to the WAVPACK2CELL and WAVCELL2PACK when used.
%
%   Boundary handling:
%   ------------------
%
%   FWT(f,w,J,'per') (default) uses the periodic extension which considers
%   the input signal as it was a one period of some infinite periodic signal
%   as is natural for transforms based on the FFT. The resulting wavelet
%   representation is non-expansive, that is if the input signal length is a
%   multiple of a J-th power of the subsampling factor and the filterbank
%   is critically subsampled, the total number of coefficients is equal to
%   the input signal length. The input signal is padded with zeros to the
%   next legal length L internally.
%
%   The default periodic extension can result in "false" high wavelet
%   coefficients near the boundaries due to the possible discontinuity
%   introduced by the zero padding and periodic boundary treatment.
%
%   FWT(f,w,J,ext) with ext other than 'per' computes a slightly
%   redundant wavelet representation of the input signal f with the chosen
%   boundary extension ext. The redundancy (expansivity) of the
%   represenation is the price to pay for using general filterbank and
%   custom boundary treatment.  The extensions are done at each level of the
%   transform internally rather than doing the prior explicit padding.
%
%   The supported possibilities are:
%
%     'zero'   Zeros are considered outside of the signal (coefficient)
%              support.
%
%     'even'   Even symmetric extension.
%
%     'odd'    Odd symmetric extension.
%
%   Note that the same flag has to be used in the call of the inverse 
%   transform function IFWT if the info struct is not used.
%
%   Examples:
%   ---------
%
%   A simple example of calling the FWT function using 'db8' wavelet
%   filters.:
%
%     [f,fs] = greasy;
%     J = 10;
%     [c,info] = fwt(f,'db8',J);
%     plotwavelets(c,info,fs,'dynrange',90);
%
%   Frequency bands of the transform with x-axis in a log scale and band
%   peaks normalized to 1. Only positive frequency band is shown. :
%
%     [g,a] = wfbt2filterbank({'db8',10,'dwt'});
%     filterbankfreqz(g,a,20*1024,'linabs','posfreq','plot','inf','flog');
%
%
%   References:
%     S. Mallat. A wavelet tour of signal processing. Academic Press, San
%     Diego, CA, 1998.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/fwt.html}
%@seealso{ifwt, plotwavelets, wavpack2cell, wavcell2pack, thresh}
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


complainif_notenoughargs(nargin,3,'FWT');
complainif_notposint(J,'J');

% Initialize the wavelet filters structure
w = fwtinit(w);


%% ----- step 0 : Check inputs -------
definput.import = {'fwt'};
definput.keyvals.dim = [];
definput.flags.cfmt = {'pack','cell'};
[flags,~,dim]=ltfatarghelper({'dim'},definput,varargin);


%% ----- step 1 : Verify f and determine its length -------
[f,~,Ls,~,dim]=assert_sigreshape_pre(f,[],dim,upper(mfilename));

%% ----- step 2 : Determine number of ceoefficients in each subband *Lc*
%  and next legal input data length *L*.
[Lc, L] = fwtclength(Ls,w,J,flags.ext);

% Pad with zeros if the safe length L differ from the Ls.
if(Ls~=L)
   f=postpad(f,L);
end

%% ----- step 3 : Run computation.
c = comp_fwt(f,w.h,w.a,J,flags.ext);

%% ----- FINALIZE: Change format of coefficients.
if flags.do_pack
   c = wavcell2pack(c,dim);
end

%% ----- FILL INFO STRUCT ----------------------
if nargout>1
   info.fname = 'fwt';
   info.wt = w;
   info.ext = flags.ext;
   info.Lc = Lc;
   info.J = J;
   info.dim = dim;
   info.Ls = Ls;
   info.isPacked = flags.do_pack;
end
%END FWT

