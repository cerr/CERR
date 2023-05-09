function [ sol ] = proj_dual( x,~, param )
%-*- texinfo -*-
%@deftypefn {Function} proj_dual
%@verbatim
%PROJ_DUAL projection onto the dual windows space
%   Usage:  sol=proj_proj(x, ~, param)
%           [sol, infos]=proj_b2(x, ~, param)
%
%   Input parameters:
%         x     : Input signal.
%         param : Structure of optional parameters.
%   Output parameters:
%         sol   : Solution.
%         infos : Structure summarizing informations at convergence
%
%   PROJ_DUAL(x,~,param) solves:
%
%      sol = argmin_{z} ||x - z||_2^2   s.t.  A z=y
%
%   param is a Matlab structure containing the following fields:
%
%    param.y : measurements (default: 0).
%
%    param.A : Matrix (default: Id).
%
%    param.AAtinv : (A A^*)^(-1) Define this parameter to speed up computation.
%
%    param.verbose : 0 no log, 1 a summary at convergence, 2 print main
%     steps (default: 1)
%
%
%   infos is a Matlab structure containing the following fields:
%
%    infos.algo : Algorithm used
%
%    infos.iter : Number of iteration
%
%    infos.time : Time of execution of the function in sec.
%
%    infos.final_eval : Final evaluation of the function
%
%    infos.crit : Stopping critterion used 
%
%    infos.residue : Final residue  
%
%
%   Rem: The input "~" is useless but needed for compatibility issue.
%
%
%   References:
%     M.-J. Fadili and J.-L. Starck. Monotone operator splitting for
%     optimization problems in sparse recovery. In Image Processing (ICIP),
%     2009 16th IEEE International Conference on, pages 1461--1464. IEEE,
%     2009.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/proj_dual.html}
%@seealso{prox_l2, proj_b1}
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

%
% Author: Nathanael Perraudin
% Date: Feb 20, 2013
%

% Start the time counter
t1 = tic;

% Optional input arguments
if ~isfield(param, 'y'), param.y = 0; end
if ~isfield(param, 'A'), param.A = eye(length(x)); end
if ~isfield(param, 'AAtinv'), param.AAtinv=pinv(A*At); end
if ~isfield(param, 'verbose'), param.verbose = 1; end


% Projection  
   
sol = x - param.A'*param.AAtinv*(param.A*x-param.y);
crit = 'TOL_EPS'; iter = 0; u = NaN;
    


% Log after the projection onto the L2-ball
error=norm(param.y-param.A *sol );
if param.verbose >= 1
    fprintf(['  Proj. dual windows: ||y-Ax||_2 = %e,', ...
        ' %s, iter = %i\n'],error , crit, iter);
end

% Infos about algorithm
infos.algo=mfilename;
infos.iter=iter;
infos.final_eval=error;
infos.crit=crit;
infos.residue=u;
infos.time=toc(t1);

end



