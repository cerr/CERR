function [tc,relres,iter,xrec] = gabelitistlasso(x,g,a,M,lambda,varargin)
%-*- texinfo -*-
%@deftypefn {Function} gabelitistlasso
%@verbatim
%GABELITISTLASSO  Elitist LASSO regression in Gabor domain
%   Usage: [tc,xrec] = gabelitistlasso(x,g,a,M,lambda,C,tol,maxit)
%   Input parameters:
%       x        : Input signal
%       g        : Synthesis window function
%       a        : Length of time shift
%       M        : Number of channels
%       lambda   : Regularization parameter, controls sparsity of the
%                  solution
%   Output parameters:
%      tc        : Thresholded coefficients
%      relres    : Vector of residuals.
%      iter      : Number of iterations done.
%      xrec      : Reconstructed signal
%
%   GABELITISTLASSO(x,g,a,M,lambda) solves the elitist LASSO regression
%   problem in the Gabor domain: minimize a functional of the synthesis
%   coefficients defined as the sum of half the l^2 norm of the
%   approximation error and the mixed l^2 / l^1 norm of the coefficient
%   sequence, with a penalization coefficient lambda.
%  
%   The matrix of Gabor coefficients is labelled in terms of groups and
%   members.  The obtained expansion is sparse in terms of groups, no
%   sparsity being imposed to the members of a given group. This is achieved
%   by a regularization term composed of l^2 norm within a group, and l^1 norm
%   with respect to groups.
%
%   [tc,relres,iter] = GABELITISTLASSO(...) returns the residuals relres*
%   in a vector and the number of iteration steps done, maxit.
%
%   [tc,relres,iter,xrec] = GABELITISTLASSO(...) returns the reconstructed
%   signal from the coefficients, xrec. Note that this requires additional
%   computations.
%
%   The function takes the following optional parameters at the end of
%   the line of input arguments:
%
%     'freq'     Group in frequency (search for tonal components). This is the
%                default.
%
%     'time'     Group in time (search for transient components). 
%
%     'C',cval   Landweber iteration parameter: must be larger than
%                square of upper frame bound. Default value is the upper
%                frame bound.
%
%     'tol',tol  Stopping criterion: minimum relative difference between
%                norms in two consecutive iterations. Default value is
%                1e-2.
%
%     'maxit',maxit
%                Stopping criterion: maximal number of iterations to do. Default value is 100.
%
%     'print'    Display the progress.
%
%     'quiet'    Don't print anything, this is the default.
%
%     'printstep',p
%                If 'print' is specified, then print every p'th
%                iteration. Default value is 10;
%
%   The parameters C, itermax and tol may also be specified on the
%   command line in that order: gabgrouplasso(x,g,a,M,lambda,C,tol,maxit).
%
%   The solution is obtained via an iterative procedure, called Landweber
%   iteration, involving iterative group thresholdings.
%
%   The relationship between the output coefficients is given by :
%
%     xrec = idgt(tc,g,a);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/deprecated/gabelitistlasso.html}
%@seealso{gablasso, gabframebounds}
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

warning(['LTFAT: GABELITISTLASSO has been deprecated, please use FRANAGROUPLASSO ' ...
         'instead. See the help on FRANAGROUPLASSO for more details.']);

if nargin<5
  error('%s: Too few input parameters.',upper(mfilename));
end;

if ~isvector(x)
    error('Input signal must be a vector.');
end

% Define initial value for flags and key/value pairs.
definput.flags.group={'freq','time'};

definput.keyvals.C=[];
definput.keyvals.itermax=100;
definput.keyvals.tol=1e-2;
definput.keyvals.printstep=10;
definput.flags.print={'print','quiet'};

[flags,kv]=ltfatarghelper({'C','tol','maxit'},definput,varargin);

% Determine transform length, and calculate the window.
[x,g,L] = gabpars_from_windowsignal(x,g,a,M,[],'GABELITISTLASSO');

if isempty(kv.C)
  [A_dummy,kv.C] = gabframebounds(g,a,M,L);
end;


tchoice = flags.do_time;
N = floor(length(x)/a);

% Normalization to turn lambda to a value comparable to lasso
if tchoice
    lambda = lambda * sqrt(N);
else
    lambda = lambda * sqrt(M);
end

% Various parameter initializations
threshold = lambda/kv.C;

% Initialization of thresholded coefficients
c0 = dgt(x,g,a,M);
tc0 = c0;
relres = 1e16;
iter = 0;

% Main loop
while ((iter < kv.itermax)&&(relres >= kv.tol))
    tc = c0 - dgt(idgt(tc0,g,a),g,a,M);
    tc = tc0 + tc/kv.C;
    if tchoice
        tc = tc';
    end;
    tc = elitistthresh(tc,threshold,'soft');
    if tchoice
        tc = tc';
    end;
    relres = norm(tc(:)-tc0(:))/norm(tc0(:));
    tc0 = tc;
    iter = iter + 1;
    if flags.do_print
      if mod(iter,kv.printstep)==0
        fprintf('Iteration %d: relative error = %f\n',iter,relres);
      end;
    end;
end

% Reconstruction
if nargout>3
  xrec = idgt(tc,g,a);
end;

