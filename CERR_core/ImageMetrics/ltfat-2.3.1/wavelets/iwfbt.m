function f=iwfbt(c,par,varargin)
%-*- texinfo -*-
%@deftypefn {Function} iwfbt
%@verbatim
%IWFBT   Inverse Wavelet Filterbank Tree
%   Usage:  f=iwfbt(c,info);
%           f=iwfbt(c,wt,Ls);
%
%   Input parameters:
%         c       : Coefficients stored in a cell-array.
%         info,wt : Transform parameters struct/Wavelet Filterbank tree
%         Ls      : Length of the reconstructed signal.
%
%   Output parameters:
%         f     : Reconstructed data.
%
%   f = IWFBT(c,info) reconstructs signal f from the coefficients c*
%   using parameters from info struct. both returned by WFBT function.
%
%   f = IWFBT(c,wt,Ls) reconstructs signal f from the coefficients c*
%   using filterbank tree defined by wt. Plese see WFBT function for
%   possible formats of wt. The Ls parameter is mandatory due to the
%   ambiguity of reconstruction lengths introduced by the subsampling
%   operation and by boundary treatment methods. Note that the same flag as
%   in the WFBT function have to be used, otherwise perfect reconstruction
%   cannot be obtained. Please see help for WFBT for description of the
%   flags.
%
%   Examples:
%   ---------
%
%   A simple example showing perfect reconstruction using IDTWFB:
%
%     f = gspi;
%     J = 7;
%     wt = {'db6',J};
%     c = wfbt(f,wt);
%     fhat = iwfbt(c,wt,length(f));
%     % The following should give (almost) zero
%     norm(f-fhat)
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/iwfbt.html}
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

% AUTHOR: Zdenek Prusa


complainif_notenoughargs(nargin,2,'IWFBT');

if(~iscell(c))
   error('%s: Unrecognized coefficient format.',upper(mfilename));
end

if(isstruct(par)&&isfield(par,'fname'))
   complainif_toomanyargs(nargin,2,'IWFBT');
   
   if ~strcmpi(par.fname,'wfbt')
      error(['%s: Wrong func name in info struct. ',...
             ' The info parameter was created by %s.'],...
             upper(mfilename),par.fname);
   end

   wt = wfbtinit({'dual',par.wt},par.fOrder);
   Ls = par.Ls;
   ext = par.ext;
   L = wfbtlength(Ls,wt,ext);
else
   complainif_notenoughargs(nargin,3,'IWFBT');

   %% PARSE INPUT
   definput.keyvals.Ls=[];
   definput.keyvals.dim=1;
   definput.import = {'fwt','wfbtcommon'};

   [flags,kv,Ls]=ltfatarghelper({'Ls'},definput,varargin);
   complainif_notposint(Ls,'Ls');

   ext = flags.ext;
   % Initialize the wavelet tree structure
   wt = wfbtinit(par,flags.forder);

   [Lc,L]=wfbtclength(Ls,wt,ext);

   % Do a sanity check
   if ~isequal(Lc,cellfun(@(cEl) size(cEl,1),c))
      error(['%s: The coefficient subband lengths do not comply with the'...
             ' signal length *Ls*.'],upper(mfilename));
   end
end

%% ----- step 3 : Run computation
[nodesBF, rangeLoc, rangeOut] = treeBFranges(wt,'rev');

outLengths = nodesInLen(nodesBF,L,strcmpi(ext,'per'),wt);
outLengths(end) = L;
f = comp_iwfbt(c,wt.nodes(nodesBF),outLengths,rangeLoc,rangeOut,ext);
f = postpad(f,Ls);

