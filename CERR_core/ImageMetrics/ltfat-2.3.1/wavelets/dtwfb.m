function [c,info]=dtwfb(f,dualwt,varargin)
%-*- texinfo -*-
%@deftypefn {Function} dtwfb
%@verbatim
%DTWFB Dual-Tree Wavelet Filter Bank
%   Usage:  c=dtwfb(f,dualwt);
%           c=dtwfb(f,{dualw,J});
%           [c,info]=dtwfb(...);
%
%   Input parameters:
%         f      : Input data.
%         dualwt : Dual-tree Wavelet Filter bank definition.
%
%   Output parameters:
%         c    : Coefficients stored in a cell-array.
%         info : Additional transform parameters struct.
%
%   c=DTWFBt(f,dualwt) computes dual-tree complex wavelet coefficients 
%   of the signal f. The representation is approximately 
%   time-invariant and provides analytic behaviour. Due to these facts, 
%   the resulting subbands are nearly aliasing free making them suitable 
%   for severe coefficient modifications. The representation is two times
%   redundant, provided critical subsampling of all involved filter banks.
%
%   The shape of the filterbank tree and filters used is controlled by 
%   dualwt (for possible formats see below). The output c is a 
%   cell-array with each element containing a single subband. The subbands 
%   are ordered with the increasing subband centre frequency. 
%
%   In addition, the function returns struct. info containing transform 
%   parameters. It can be conveniently used for the inverse transform
%   IDTWFB e.g. fhat = iDTWFB(c,info). It is also required by
%   the PLOTWAVELETS function.
%
%   If f is a matrix, the transform is applied to each column.
%
%   Two formats of dualwt are accepted:
% 
%   1) Cell array of parameters. First two elements of the array are 
%      mandatory {dualw,J}. 
% 
%      dualw   
%        Basic dual-tree filters
%      J*
%        Number of levels of the filter bank tree
%
%      Possible formats of dualw are the same as in FWTINIT except the
%      wfiltdt_ prefix is used when searching for function specifying
%      the actual impulse responses. These filters were designed specially
%      for the dual-tree filter bank to achieve the half-sample shift 
%      ultimately resulting in analytic (complex) behaviour of the 
%      transform.
%      
%      The default shape of the filter bank tree is DWT i.e. only low-pass
%      output is decomposed further (*J times in total).
%
%      Different filter bank tree shapes can be obtained by passing
%      additional flag in the cell array. Supported flags (mutually
%      exclusive) are:
%
%      'dwt'
%         Plain DWT tree (default). This gives one band per octave freq. 
%         resolution when using 2 channel basic wavelet filter bank.
%
%      'full'
%         Full filter bank tree. Both (all) basic filter bank outputs are
%         decomposed further up to depth J achieving linear frequency band
%         division.
%
%      'doubleband','quadband','octaband'
%         The filter bank is designed such that it mimics 4-band, 8-band or
%         16-band complex wavelet transform provided the basic filter bank
%         is 2 channel. In this case, J is treated such that it defines
%         number of levels of 4-band, 8-band or 16-band transform.
%
%      The dual-tree wavelet filter bank can use any basic wavelet
%      filter bank in the first stage of both trees, provided they are 
%      shifted by 1 sample (done internally). A custom first stage 
%      filter bank can be defined by passing the following
%      key-value pair in the cell array:
%
%      'first',w 
%         w defines a regular basic filter bank. Accepted formats are the
%         same as in FWTINIT assuming the wfilt_ prefix.
%
%      Similarly, when working with a filter bank tree containing
%      decomposition of high-pass outputs, some filters in both trees must
%      be replaced by a regular basic filter bank in order to achieve the
%      approximately analytic behaviour. A custom filter bank can be
%      specified by passing another key-value pair in the cell array:
%
%      'leaf',w 
%         w defines a regular basic filter bank. Accepted formats are the
%         same as in FWTINIT assuming the wfilt_ prefix.      
%
%   2) Another possibility is to pass directly a struct. returned by 
%      DTWFBINIT and possibly modified by WFBTREMOVE. 
%
%   Optional args.:
%   ---------------
%
%   In addition, the following flag groups are supported:
%
%   'freq','nat'
%      Frequency or natural (Paley) ordering of coefficient subbands.
%      By default, subbands are ordered according to frequency. The natural
%      ordering is how the subbands are obtained from the filter bank tree
%      without modifications. The ordering differs only in non-plain DWT
%      case.
%
%   Boundary handling:
%   ------------------
%
%   In contrast with FWT, WFBT and WPFBT, this function supports
%   periodic boundary handling only.
%
%   Examples:
%   ---------
%   
%   A simple example of calling the DTWFB function using the regular
%   DWT iterated filter bank. The second figure shows a magnitude frequency
%   response of an identical filter bank.:
% 
%     [f,fs] = greasy;
%     J = 6;
%     [c,info] = dtwfb(f,{'qshift3',J});
%     figure(1);
%     plotwavelets(c,info,fs,'dynrange',90);
%     figure(2);
%     [g,a] = dtwfb2filterbank({'qshift3',J});
%     filterbankfreqz(g,a,1024,'plot','linabs');
%
%   The second example shows a decomposition using a full filter bank tree
%   of depth J*:
%
%     [f,fs] = greasy;
%     J = 5;
%     [c,info] = dtwfb(f,{'qshift4',J,'full'});
%     figure(1);
%     plotwavelets(c,info,fs,'dynrange',90);
%     figure(2);
%     [g,a] = dtwfb2filterbank({'qshift4',J,'full'});
%     filterbankfreqz(g,a,1024,'plot','linabs');
%
%
%   References:
%     I. Selesnick, R. Baraniuk, and N. Kingsbury. The dual-tree complex
%     wavelet transform. Signal Processing Magazine, IEEE, 22(6):123 -- 151,
%     nov. 2005.
%     
%     N. Kingsbury. Complex wavelets for shift invariant analysis and
%     filtering of signals. Applied and Computational Harmonic Analysis,
%     10(3):234 -- 253, 2001.
%     
%     I. Bayram and I. Selesnick. On the dual-tree complex wavelet packet and
%     m-band transforms. Signal Processing, IEEE Transactions on,
%     56(6):2298--2310, June 2008.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/dtwfb.html}
%@seealso{dtwfbreal, idtwfb, plotwavelets, dtwfb2filterbank}
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

% Author: Zdenek Prusa
% Date:   30.6.2014

complainif_notenoughargs(nargin,2,'DTWFB');

definput.import = {'wfbtcommon'};
flags =ltfatarghelper({},definput,varargin);

% Initialize the wavelet tree structure
dtw = dtwfbinit(dualwt,flags.forder);
    
%% ----- step 1 : Verify f and determine its length -------
[f,Ls]=comp_sigreshape_pre(f,upper(mfilename),0);

% Determine next legal input data length.
L = wfbtlength(Ls,dtw,'per');

% Pad with zeros if the safe length L differs from the Ls.
if(Ls~=L)
   f=postpad(f,L); 
end

%% ----- step 3 : Run computation
[nodesBF, rangeLoc, rangeOut] = treeBFranges(dtw);

c = comp_dtwfb(f,dtw.nodes(nodesBF),dtw.dualnodes(nodesBF),rangeLoc,...
               rangeOut,'per',1);

%% ----- Optionally : Fill info struct ----
if nargout>1
   % Transform name
   info.fname = 'dtwfb';
   % Dual-Tree struct.
   info.wt = dtw;
   % Periodic boundary handling
   info.ext = 'per';
   % Lengths of subbands
   info.Lc = cellfun(@(cEl) size(cEl,1),c);
   % Signal length
   info.Ls = Ls;
   % Ordering of the subbands
   info.fOrder = flags.forder;
   % Cell format
   info.isPacked = 0;
end



