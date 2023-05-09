function f=idtwfb(c,par,varargin)
%-*- texinfo -*-
%@deftypefn {Function} idtwfb
%@verbatim
%IDTWFB Inverse Dual-tree Filterbank
%   Usage:  f=idtwfb(c,info);
%           f=idtwfb(c,dualwt,Ls);
%
%   Input parameters:
%         c       : Input coefficients.
%         info    : Transform params. struct
%         dualwt  : Dual-tree Wavelet Filterbank definition
%         Ls      : Length of the reconstructed signal.
%
%   Output parameters:
%         f     : Reconstructed data.
%
%   f = IDTWFB(c,info) reconstructs signal f from the coefficients c*
%   using parameters from info struct. both returned by DTWFB function.
%
%   f = IDTWFB(c,dualwt,Ls) reconstructs signal f from the coefficients
%   c using dual-tree filterbank defined by dualwt. Plese see DTWFB 
%   for supported formats. The Ls parameter is mandatory due to the
%   ambiguity of reconstruction lengths introduced by the subsampling
%   operation. 
%   Note that the same flag as in the DTWFB function have to be used, 
%   otherwise perfect reconstruction cannot be obtained. Please see help 
%   for DTWFB for description of the flags.
%
%   Examples:
%   ---------
%
%   A simple example showing perfect reconstruction using IDTWFB:
%
%      f = gspi;
%      J = 7;
%      wtdef = {'qshift3',J};
%      c = dtwfb(f,wtdef);
%      fhat = idtwfb(c,wtdef,length(f));
%      % The following should give (almost) zero
%      norm(f-fhat)
%
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/idtwfb.html}
%@seealso{dtwfb, dtwfbinit}
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


complainif_notenoughargs(nargin,2,'IDTWFB');

if ~iscell(c)
   error('%s: Unrecognized coefficient format.',upper(mfilename));
end

if(isstruct(par)&&isfield(par,'fname'))
   complainif_toomanyargs(nargin,2,'IDTWFB');
   
   if ~strcmpi(par.fname,'dtwfb')
      error(['%s: Wrong func name in info struct. ',...
             ' The info parameter was created by %s.'],...
             upper(mfilename),par.fname);
   end

   dtw = dtwfbinit({'dual',par.wt},par.fOrder);
   Ls = par.Ls;
   ext = 'per';
   L = wfbtlength(Ls,dtw,ext);
else
   complainif_notenoughargs(nargin,3,'IDTWFB');

   %% PARSE INPUT
   definput.keyvals.Ls=[];
   definput.import = {'wfbtcommon'};

   [flags,kv,Ls]=ltfatarghelper({'Ls'},definput,varargin);
   complainif_notposint(Ls,'Ls');

   ext = 'per';
   % Initialize the wavelet tree structure
   dtw = dtwfbinit(par,flags.forder);

   [Lc,L]=wfbtclength(Ls,dtw,ext);
   Lc = [Lc;Lc(end:-1:1)];

   % Do a sanity check
   if ~isequal(Lc,cellfun(@(cEl) size(cEl,1),c))
      error(['%s: The coefficient subband lengths do not comply with the'...
             ' signal length *Ls*.'],upper(mfilename));
   end
end

%% ----- step 3 : Run computation
[nodesBF, rangeLoc, rangeOut] = treeBFranges(dtw,'rev');
outLengths = nodesInLen(nodesBF,L,strcmpi(ext,'per'),dtw);
outLengths(end) = L;

f = comp_idtwfb(c,dtw.nodes(nodesBF),dtw.dualnodes(nodesBF),outLengths,...
                rangeLoc,rangeOut,ext,1);
f = postpad(f,Ls);

