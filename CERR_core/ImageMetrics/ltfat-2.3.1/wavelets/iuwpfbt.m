function f=iuwpfbt(c,par,varargin)
%-*- texinfo -*-
%@deftypefn {Function} iuwpfbt
%@verbatim
%IUWPFBT Inverse Undecimated Wavelet Packet Filterbank Tree
%   Usage:  f=iuwpfbt(c,info);
%           f=iuwpfbt(c,wt);
%
%   Input parameters:
%         c       : Coefficients stored in L xM matrix.
%         info,wt : Transform parameters struct/Wavelet tree definition.
%
%   Output parameters:
%         f     : Reconstructed data.
%
%   f = IUWPFBT(c,info) reconstructs signal f from the wavelet packet
%   coefficients c using parameters from info struct. both returned by
%   the UWPFBT function.
%
%   f = IUWPFBT(c,wt) reconstructs signal f from the wavelet packet 
%   coefficients c using the undecimated wavelet filterbank tree 
%   described by wt.
%
%   Please see help for WFBT description of possible formats of wt.
%
%   Filter scaling:
%   ---------------
%
%   As in UWPFBT, the function recognizes three flags controlling scaling
%   of filters:
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
%   If 'noscale' is used, 'scale' must have been used in UWPFBT (and vice
%   versa) in order to obtain a perfect reconstruction.
%
%   Scaling of intermediate outputs:
%   --------------------------------
%
%   The following flags control scaling of the intermediate coefficients.
%   The intermediate coefficients are outputs of nodes which ale also
%   inputs to nodes further in the tree.
%
%      'intsqrt'
%               Each intermediate output is scaled by 1/sqrt(2).
%               If the filterbank in each node is orthonormal, the overall
%               undecimated transform is a tight frame.
%               This is the default.
%
%      'intnoscale'
%               No scaling of intermediate results is used.
%
%      'intscale'
%               Each intermediate output is scaled by 1/2.
%
%   If 'intnoscale' is used, 'intscale' must have been used in UWPFBT
%   (and vice versa) in order to obtain a perfect reconstruction.
%
%   Examples:
%   ---------
%
%   A simple example showing perfect reconstruction using the "full 
%   decomposition" wavelet tree:
%
%     f = greasy;
%     J = 7;
%     wtdef = {'db10',J,'full'};
%     c = uwpfbt(f,wtdef);
%     fhat = iuwpfbt(c,wtdef);
%     % The following should give (almost) zero
%     norm(f-fhat)
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/iuwpfbt.html}
%@seealso{wfbt, wfbtinit}
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

complainif_notenoughargs(nargin,2,'IUWPFBT');

if isempty(c) || ~isnumeric(c)
   error('%s: Unrecognized coefficient format.',upper(mfilename));
end

if(isstruct(par)&&isfield(par,'fname'))
   complainif_toomanyargs(nargin,2,'IUWPFBT');

   if ~strcmpi(par.fname,'uwpfbt')
      error(['%s: Wrong func name in info struct. The info parameter ',... 
             'was created by %s.'],upper(mfilename),par.fname);
   end
   wt = wfbtinit({'dual',par.wt},par.fOrder);
   
   scaling = par.scaling;
   interscaling = par.interscaling;
   
   % Use the "oposite" scaling of intermediate node outputs
   if strcmp(interscaling,'intscale')
      interscaling = 'intnoscale';
   elseif strcmp(interscaling,'intnoscale')
      interscaling = 'intscale';
   end
   
   % Use the "oposite" scaling of filters
   if strcmp(scaling,'scale')
      scaling = 'noscale';
   elseif strcmp(scaling,'noscale')
      scaling = 'scale';
   end
   
else
   definput.import = {'wfbtcommon','uwfbtcommon'};
   definput.flags.interscaling = {'intsqrt', 'intscale', 'intnoscale'};
   [flags]=ltfatarghelper({},definput,varargin);
   
   scaling = flags.scaling;
   interscaling = flags.interscaling;
   % Initialize the wavelet tree structure
   wt = wfbtinit(par,flags.forder);
end

wtPath = fliplr(nodeBForder(0,wt));
[pOutIdxs,chOutIdxs] = treeWpBFrange(wt);
nodesUps = nodesFiltUps(wtPath,wt);
f = comp_iuwpfbt(c,wt.nodes(wtPath),nodesUps,pOutIdxs,chOutIdxs,scaling,...
                 interscaling);

