function f = iufwt(c,par,varargin)
%-*- texinfo -*-
%@deftypefn {Function} iufwt
%@verbatim
%IUFWT   Inverse Undecimated Fast Wavelet Transform
%   Usage:  f = iufwt(c,info)
%           f = iufwt(c,w,J);
%
%   Input parameters:
%         c      : Coefficients stored in L xJ+1 matrix.
%         info,w : Transform parameters struct/Wavelet filters definition.
%         J      : Number of filterbank iterations.
%
%   Output parameters:
%         f     : Reconstructed data.
%
%   f = IUFWT(c,info) reconstructs signal f from the wavelet
%   coefficients c using parameters from info struct. both returned by
%   UFWT function.
%
%   f = IUFWT(c,w,J) reconstructs signal f from the wavelet
%   coefficients c using the wavelet filterbank consisting of the J*
%   levels of the basic synthesis filterbank defined by w using the "a-trous"
%   algorithm. Node that the same flag as in the ufwt function have to be used.
%
%   Please see the help on UFWT for a description of the parameters.
%
%   Filter scaling
%   --------------
%
%   As in UFWT, 3 flags defining scaling of filters are recognized:
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
%   If 'noscale' is used, 'scale' must have been used in UFWT (and vice
%   versa) in order to obtain a perfect reconstruction.
%
%   Examples:
%   ---------
%
%   A simple example showing perfect reconstruction:
%
%     f = gspi;
%     J = 8;
%     c = ufwt(f,'db8',J);
%     fhat = iufwt(c,'db8',J);
%     % The following should give (almost) zero
%     norm(f-fhat)
%
%
%   References:
%     S. Mallat. A wavelet tour of signal processing. Academic Press, San
%     Diego, CA, 1998.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/iufwt.html}
%@seealso{ufwt, plotwavelets}
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

complainif_notenoughargs(nargin,2,'IUFWT');

if(isstruct(par)&&isfield(par,'fname'))
   complainif_toomanyargs(nargin,2,'IUFWT');
   
   if ~strcmpi(par.fname,'ufwt')
      error(['%s: Wrong func name in info struct. ',...
             ' The info parameter was created by %s.'],...
             upper(mfilename),par.fname);
   end

   % Ensure we are using the correct wavelet filters
   w = fwtinit({'dual',par.wt});
   J = par.J;
   scaling = par.scaling;
   % Use the "oposite" scaling
   if strcmp(scaling,'scale')
       scaling = 'noscale';
   elseif strcmp(scaling,'noscale')
       scaling = 'scale';
   end
else
   complainif_notenoughargs(nargin,3,'IUFWT');

   definput.keyvals.J = [];
   definput.import = {'uwfbtcommon'};
   [flags, ~, J]=ltfatarghelper({'J'},definput,varargin);
   complainif_notposint(J,'J');

   % Initialize the wavelet filters
   % It is up to user to use the correct ones.
   w = fwtinit(par);
   scaling = flags.scaling;
end


%%  Run computation
f = comp_iufwt(c,w.g,w.a,J,scaling);








