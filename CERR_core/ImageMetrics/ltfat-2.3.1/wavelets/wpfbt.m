function [c,info]=wpfbt(f,wt,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wpfbt
%@verbatim
%WPFBT   Wavelet Packet FilterBank Tree
%   Usage:  c=wpfbt(f,wt);
%           [c,info]=wpfbt(...);
%
%   Input parameters:
%         f   : Input data.
%         wt  : Wavelet Filterbank tree definition.
%
%   Output parameters:
%         c    : Coefficients stored in a cell-array.
%         info : Transform parameters struct.
%
%   c=WPFBT(f,wt) returns wavelet packet coefficients c obtained by
%   applying a wavelet filterbank tree defined by wt to the input data
%   f. 
%    
%   [c,info]=WPFBT(f,wt) additionally returns struct. info containing 
%   transform parameters. It can be conviniently used for the inverse 
%   transform IWPFBT e.g. fhat = iWPFBT(c,info). It is also required 
%   by the PLOTWAVELETS function.
%
%   In contrast to WFBT, the cell array c contain every intermediate 
%   output of each node in the tree. c{jj} are ordered according to
%   nodes taken in the breadth-first order.
%
%   If f is row/column vector, the coefficient vectors c{jj} are
%   columns. If f is a matrix, the transformation is applied to each of
%   column of the matrix.
%
%   Scaling of intermediate outputs:
%   --------------------------------
%
%   The following flags control scaling of intermediate outputs and
%   therefore the energy relations between coefficient subbands. An 
%   intermediate output is an output of a node which is further used as an
%   input to a descendant node.
%
%      'intsqrt'
%               Each intermediate output is scaled by 1/sqrt(2).
%               If the filterbank in each node is orthonormal, the overall
%               undecimated transform is a tight frame.
%               This is the default.
%
%      'intnoscale'
%               No scaling of intermediate results is used. This is
%               necessaty for the WPBEST function to correctly work with
%               the cost measures.
%
%      'intscale'
%               Each intermediate output is scaled by 1/2.
%
%   If 'intnoscale' is used, 'intscale' must be used in IWPFBT (and vice
%   versa) in order to obtain a perfect reconstruction.
%
%   Please see help for WFBT description of possible formats of wt and
%   of the additional flags defining boundary handling.
%
%   Examples:
%   ---------
%
%   A simple example of calling the WPFBT function using the "full
%   decomposition" wavelet tree:
%
%     f = gspi;
%     J = 6;
%     [c,info] = wpfbt(f,{'sym10',J,'full'});
%     plotwavelets(c,info,44100,'dynrange',90);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wpfbt.html}
%@seealso{wfbt, iwpfbt, wfbtinit, plotwavelets, wpbest}
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

complainif_notenoughargs(nargin,2,'WPFBT');

definput.import = {'fwt','wfbtcommon'};
definput.flags.interscaling = {'intsqrt', 'intscale', 'intnoscale'};
[flags]=ltfatarghelper({},definput,varargin);

% Initialize the wavelet tree structure
wt = wfbtinit(wt,flags.forder);

%% ----- step 1 : Verify f and determine its length -------
[f,Ls]=comp_sigreshape_pre(f,upper(mfilename),0);
if(Ls<2)
   error('%s: Input signal seems not to be a vector of length > 1.',...
       upper(mfilename));
end

% Determine next legal input data length.
L = wfbtlength(Ls,wt,flags.ext);

% Pad with zeros if the safe length L differ from the Ls.
if(Ls~=L)
   f=postpad(f,L);
end

%% ----- step 3 : Run computation
wtPath = nodeBForder(0,wt);
rangeLoc = nodesLocOutRange(wtPath,wt);
c = comp_wpfbt(f,wt.nodes(wtPath),rangeLoc,flags.ext,flags.interscaling);

%% ----- Optional : Fill the info struct. -----
if nargout>1
   info.fname = 'wpfbt';
   info.wt = wt;
   info.ext = flags.ext;
   info.Lc = cellfun(@(cEl) size(cEl,1),c);
   info.Ls = Ls;
   info.fOrder = flags.forder;
   info.isPacked = 0;
   info.interscaling = flags.interscaling;
end

