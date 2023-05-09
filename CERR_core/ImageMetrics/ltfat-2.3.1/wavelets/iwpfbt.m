function f=iwpfbt(c,par,varargin)
%-*- texinfo -*-
%@deftypefn {Function} iwpfbt
%@verbatim
%IWPFBT   Inverse Wavelet Packet Filterbank Tree
%   Usage:  f=iwpfbt(c,info);
%           f=iwpfbt(c,wt,Ls);
%
%   Input parameters:
%         c       : Coefficients stored in a cell-array.
%         info,wt : Transform parameters struct/Wavelet Filterbank tree.
%         Ls      : Length of the reconstructed signal.
%
%   Output parameters:
%         f     : Reconstructed data.
%
%   f = IWPFBT(c,info) reconstructs signal f from the coefficients c*
%   using parameters from info struct. both returned by WFBT function.
%
%   f = IWPFBT(c,wt,Ls) reconstructs signal f from the coefficients c*
%   using filter bank tree defined by wt. Plese see WFBT function for
%   possible formats of wt. The Ls parameter is mandatory due to the
%   ambiguity of reconstruction lengths introduced by the subsampling
%   operation and by boundary treatment methods.
%
%   Please see help for WFBT description of possible formats of wt and
%   of the additional flags.
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
%   If 'intnoscale' is used, 'intscale' must have been used in WPFBT
%   (and vice versa) in order to obtain a perfect reconstruction.
%
%   Examples:
%   ---------
%
%   A simple example showing perfect reconstruction using the "full
%   decomposition" wavelet tree:
%
%     f = gspi;
%     J = 7;
%     wt = {'db10',J,'full'};
%     c = wpfbt(f,wt);
%     fhat = iwpfbt(c,wt,length(f));
%     % The following should give (almost) zero
%     norm(f-fhat)
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/iwpfbt.html}
%@seealso{wpfbt, wfbtinit}
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
complainif_notenoughargs(nargin,2,'IWPFBT');

if(~iscell(c))
    error('%s: Unrecognized coefficient format.',upper(mfilename));
end


if(isstruct(par)&&isfield(par,'fname'))
   complainif_toomanyargs(nargin,2,'IWPFBT');

   if ~strcmpi(par.fname,'wpfbt')
      error('%s: Wrong func name in info struct. The info parameter was created by %s.',upper(mfilename),par.fname);
   end

   wt = wfbtinit({'dual',par.wt},par.fOrder);
   Ls = par.Ls;
   ext = par.ext;
   interscaling = par.interscaling;
   % Use the "oposite" scaling
   if strcmp(interscaling,'intscale')
      interscaling = 'intnoscale';
   elseif strcmp(interscaling,'intnoscale')
      interscaling = 'intscale';
   end

   % Determine next legal input data length.
   L = wfbtlength(Ls,wt,ext);
else
   if nargin<3
      error('%s: Too few input parameters.',upper(mfilename));
   end
   %% PARSE INPUT
   definput.keyvals.Ls=[];
   definput.import = {'fwt','wfbtcommon'};
   definput.flags.interscaling = {'intsqrt', 'intscale', 'intnoscale'};
   [flags,kv,Ls]=ltfatarghelper({'Ls'},definput,varargin);
   complainif_notposint(Ls,'Ls');

   ext = flags.ext;
   interscaling = flags.interscaling;
   % Initialize the wavelet tree structure
   wt = wfbtinit(par,flags.forder);

   [Lc,L]=wpfbtclength(Ls,wt,ext);

   % Do a sanity check
   if ~isequal(Lc,cellfun(@(cEl) size(cEl,1),c))
      error(['%s: The coefficients subband lengths do not comply with the'...
             ' signal length *Ls*.'],upper(mfilename));
   end

end


wtPath = fliplr(nodeBForder(0,wt));
[pOutIdxs,chOutIdxs] = treeWpBFrange(wt);
f = comp_iwpfbt(c,wt.nodes(wtPath),pOutIdxs,chOutIdxs,L,ext,interscaling);
f = postpad(f,Ls);

