function [c,info]=uwfbt(f,wt,varargin)
%-*- texinfo -*-
%@deftypefn {Function} uwfbt
%@verbatim
%UWFBT   Undecimated Wavelet FilterBank Tree
%   Usage:  c=uwfbt(f,wt);
%           [c,info]=uwfbt(...);
%
%   Input parameters:
%         f   : Input data.
%         wt  : Wavelet Filterbank tree
%
%   Output parameters:
%         c     : Coefficients stored in L xM matrix.
%
%   UWFBT(f,wt) computes redundant time (or shift) invariant 
%   representation of the input signal f using the filterbank tree 
%   definition in wt and using the "a-trous" algorithm. 
%   Number of columns in c (*M*) is defined by the total number of 
%   outputs of nodes of the tree.
%
%   [c,info]=UWFBT(f,wt) additionally returns struct. info containing
%   the transform parameters. It can be conviniently used for the inverse
%   transform IUWFBT e.g. fhat = iUWFBT(c,info). It is also required 
%   by the PLOTWAVELETS function.
%
%   If f is a matrix, the transformation is applied to each of W columns
%   and the coefficients in c are stacked along the third dimension.
%
%   Please see help for WFBT description of possible formats of wt and
%   description of frequency and natural ordering of the coefficient subbands.
%
%   Filter scaling
%   --------------
%
%   When compared to WFBT, the subbands produced by UWFBT are
%   gradually more and more redundant with increasing depth in the tree.
%   This results in energy grow of the coefficients. There are 3 flags
%   defining filter scaling:
%
%      'sqrt'
%               Each filter is scaled by 1/sqrt(a), there a is the hop
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
%   If 'noscale' is used, 'scale' has to be used in IUWFBT (and vice
%   versa) in order to obtain a perfect reconstruction.
%
%   Examples:
%   ---------
%
%   A simple example of calling the UWFBT function using the "full decomposition" wavelet tree:
%
%     f = greasy;
%     J = 8;
%     [c,info] = uwfbt(f,{'sym10',J,'full'});
%     plotwavelets(c,info,16000,'dynrange',90);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/uwfbt.html}
%@seealso{iuwfbt, wfbtinit}
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

complainif_notenoughargs(nargin,2,'UWFBT');

definput.import = {'wfbtcommon','uwfbtcommon'};
flags=ltfatarghelper({},definput,varargin);

% Initialize the wavelet tree structure
wt = wfbtinit(wt,flags.forder);

%% ----- step 1 : Verify f and determine its length -------
[f,Ls]=comp_sigreshape_pre(f,upper(mfilename),0);
if(Ls<2)
   error('%s: Input signal seems not to be a vector of length > 1.',upper(mfilename));
end

%% ----- step 2 : Prepare input parameters
[nodesBF, rangeLoc, rangeOut] = treeBFranges(wt);
nodesUps = nodesFiltUps(nodesBF,wt);
%% ----- step 3 : Run computation
c = comp_uwfbt(f,wt.nodes(nodesBF),nodesUps,rangeLoc,rangeOut,flags.scaling);

%% ----- Optional : Fill the info struct. -----
if nargout>1
   info.fname = 'uwfbt';
   info.wt = wt;
   info.fOrder = flags.forder;
   info.isPacked = 0;
   info.scaling = flags.scaling;
end

